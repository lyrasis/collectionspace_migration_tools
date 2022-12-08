# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module CollectionspaceMigrationTools
  module S3
    # All the preparatory stuff to successfully spin up a CMT::S3::Uploader
    class UploaderPreparer
      include Dry::Monads[:result]
      include Dry::Monads::Do.for(:call)


      class << self
        def call(...)
          self.new(...).call
        end
      end

      def initialize(file_dir:, rectype:)
        @file_dir = "#{CMT.config.client.batch_dir}/#{file_dir}"
        @rectype = rectype
      end

      def call
        puts "Setting up for batch uploading..."

        # Make sure mapper_report CSV is present and ok since we are using it
        #   to power our uploads
        source_report_path = "#{file_dir}/mapper_report.csv"
        row_getter = yield CMT::Csv::FirstRowGetter.new(source_report_path)
        checker = yield CMT::Csv::FileChecker.call(
          source_report_path,
          row_getter
        )
        headers = checker[1].headers.map(&:downcase)

        # Verifiy our credentials/config work to create an S3 client and send
        #   a verifying command via the client to our bucket
        client = yield CMT::Build::S3Client.call

        reporter = yield CMT::S3::UploadReporter.new(
          output_dir: file_dir,
          fields: headers
        )

        uploader = yield CMT::S3::ItemUploader.new(
          file_dir: file_dir,
          rectype: rectype,
          client: client,
          reporter: reporter
        )

        batch_uploader = yield CMT::S3::BatchUploader.new(
          csv_path: source_report_path,
          uploader: uploader,
          reporter: reporter
        )

        Success(batch_uploader)
      end

      private

      attr_reader :file_dir, :rectype
    end
  end
end
