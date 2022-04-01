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
        def call(file_dir:)
          self.new(file_dir: file_dir).call
        end
      end

      def initialize(file_dir:)
        @file_dir = "#{CMT.config.client.xml_dir}/#{file_dir}"
      end

      def call
        puts "Setting up for batch uploading..."

        # Make sure mapper_report CSV is present and ok since we are using it to power our uploads
        report_path = "#{file_dir}/mapper_report.csv"
        row_getter = yield(CMT::Csv::FirstRowGetter.new(report_path))
        checker = yield(CMT::Csv::FileChecker.call(report_path, row_getter))
        headers = checker[1].headers

        # Verifiy our credentials/config work to create an S3 client and send a verifying command
        #   via the client to our bucket
        client = yield(CMT::Build::S3Client.call)

        reporter = yield(CMT::S3::UploadReporter.new(output_dir: file_dir, fields: headers))

        uploader = yield(CMT::S3::ItemUploader.new(
          file_dir: file_dir,
          client: client,
          reporter: reporter
        ))

        batch_uploader = yield(CMT::S3::BatchUploader.new(
          csv_path: report_path,
          uploader: uploader,
          reporter: reporter
        ))

        Success(batch_uploader)
      end

      private

      attr_reader :file_dir
    end
  end
end
