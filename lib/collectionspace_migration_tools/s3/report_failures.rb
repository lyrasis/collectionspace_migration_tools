# frozen_string_literal: true

require "dry/monads"
require "dry/monads/do"

module CollectionspaceMigrationTools
  module S3
    class IngestFailures
      include Dry::Monads[:result]
      include Dry::Monads::Do.for(:get_failures)

      class << self
        def call(file_dir:)
          new(file_dir: file_dir).call
        end
      end

      def initialize(file_dir:)
        @file_dir = "#{CMT.config.client.batch_dir}/#{file_dir}"
      end

      def call
        get_failures.either(
          ->(failures) { failures },
          ->(failure) {
            puts failure
            exit
          }
        )
      end

      private

      attr_reader :file_dir

      def get_failures
        client = yield(CMT::Build::S3Client.call)
      end

      def setup
        # Make sure upload_report CSV is present and ok since we are using it to power our uploads
        report_path = "#{file_dir}/upload_report.csv"
        row_getter = yield(CMT::Csv::FirstRowGetter.new(report_path))
        checker = yield(CMT::Csv::FileChecker.call(report_path, row_getter))
        headers = checker[1].headers.map(&:downcase)

        # Verifiy our credentials/config work to create an S3 client and send a verifying command
        #   via the client to our bucket

        Success(client)
      end
    end
  end
end
