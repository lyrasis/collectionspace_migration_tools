# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module CollectionspaceMigrationTools
  module S3
    # Handles uploading a single item (or skipping row) and reporting result
    class ItemUploader
      include Dry::Monads[:result]
      include Dry::Monads::Do.for(:upload)

      def initialize(file_dir:, rectype:, client:, reporter:)
        @file_dir = file_dir
        @rectype = rectype
        @client = client
        @bucket = CMT.config.client.s3_bucket
        @reporter = reporter
        @media_delay = CMT.config.client.media_with_blob_upload_delay
      end

      # @param row [CSV::Row] with headers
      def call(row)
        if mapping_failure?(row)
          reporter.report_mapping_failure(row)
        elsif uploadable?(row)
          upload(row).either(
            ->(result){ reporter.report_success(row) },
            ->(result){ reporter.report_failure(result, row) }
          )
        else
          reporter.report_unuploadable(row)
        end
      end

      def to_monad
        Success(self)
      end

      private

      attr_reader :file_dir, :rectype, :client, :bucket, :reporter, :media_delay

      def do_upload(path, s3key)
        result = client.put_object({
          body: File.read(path),
          bucket: bucket,
          key: s3key
        })
      rescue StandardError => err
        msg = "#{err.message} IN #{err.backtrace[0]}"
        Failure(CMT::Failure.new(context: "#{self.class.name}.#{__callee__}", message: msg))
      else
        return Success() if result.etag

        Failure('failed to upload without throwing error')
      end

      def xmlfile(row)
        row['cmt_output_file']
      end

      def file_exists(path)
        return Success() if File.exists?(path)

        Failure("no file exists at: #{path}")
      end

      def has_file?(row)
        file = xmlfile(row)
        true if !file.nil? && !file.empty?
      end

      def s3key(row)
        row['cmt_s3_key']
      end

      def has_key?(row)
        objkey = s3key(row)
        true if !objkey.nil? && !objkey.empty?
      end

      def mapping_failure?(row)
        row['cmt_outcome'] == 'failure'
      end

      def media_blob?(row)
        return false unless rectype == 'media'
        return false unless row.key?('mediafileuri')

        uri = row['mediafileuri']
        return false if uri.nil? || uri.empty?

        keydata = CMT::Decode.to_h(row['cmt_s3_key'])
        return false if keydata.failure?
        return false unless keydata.value![:action] == 'CREATE'

        true
      end

      def upload(row)
        path = "#{file_dir}/#{xmlfile(row)}"
        _exists = yield(file_exists(path))
        uploaded = yield(do_upload(path, s3key(row)))

        if rectype == 'media'
          sleep(media_delay) if media_blob?(row)
        end

        Success(uploaded)
      end

      def uploadable?(row)
        has_file?(row) && has_key?(row)
      end
    end
  end
end
