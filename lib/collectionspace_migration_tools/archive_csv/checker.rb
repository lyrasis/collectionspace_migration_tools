# frozen_string_literal: true

require "csv"

module CollectionspaceMigrationTools
  module ArchiveCsv
    class Checker
      include Dry::Monads[:result]
      include Dry::Monads::Do.for(:call)

      class << self
        def call(...)
          new(...).call
        end
      end

      # @param path [String]
      # @param headers [Array<String>]
      def initialize(
        path: CMT::ArchiveCsv.path,
        headers: CMT::Batch::Csv::Headers.all_headers
      )
        @path = path
        @headers = headers
      end

      def call
        _exist = yield CMT::ArchiveCsv.file_check
        table = yield CMT::ArchiveCsv.parse
        _hdrs = yield header_check(table)

        Success(table)
      end

      private

      attr_reader :path, :headers

      def header_check(table)
        return Success() if table.headers == headers

        Failure(header_check_failure_msg)
      end

      def header_check_failure_msg
        "Archive CSV headers are not up-to-date, so archiving may "\
          "fail unexpectedly. Run `thor archive:fix_csv` to fix"
      end
    end
  end
end
