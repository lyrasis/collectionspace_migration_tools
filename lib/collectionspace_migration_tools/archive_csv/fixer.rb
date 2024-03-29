# frozen_string_literal: true

require "csv"

module CollectionspaceMigrationTools
  module ArchiveCsv
    class Fixer
      include CMT::Csv::Fixable
      include Dry::Monads[:result]
      include Dry::Monads::Do.for(:call)

      class << self
        def call(...)
          new(...).call
        end
      end

      def initialize(
        path: CMT::ArchiveCsv.path,
        headers: CMT::Batch::Csv::Headers.all_headers,
        rewriter: CMT::Csv::Rewriter.new(CMT::ArchiveCsv.path)
      )
        @path = path
        @rewriter = rewriter
        @headers = headers
      end

      def call
        _present = yield CMT::ArchiveCsv.file_check
        checked = yield check
        return Success("Nothing to fix!") if checked == :ok

        parsed = yield CMT::ArchiveCsv.parse
        fixed = yield update_csv_columns(parsed, headers)
        _written = yield rewriter.call(fixed)

        Success("Updated CSV columns")
      end

      private

      attr_reader :path, :rewriter, :headers

      def check
        CMT::ArchiveCsv::Checker.call(path: path, headers: headers)
          .either(
            ->(current) { Success(:ok) },
            ->(needsfix) { Success() }
          )
      end
    end
  end
end
