# frozen_string_literal: true

module CollectionspaceMigrationTools
  module Csid
    # Value object representing data given to Deleter, and its result
    class DeleteResult
      def initialize(row:, result:)
        @row = row
        @result = result
      end

      def headers
        to_h.keys
      end

      def to_monad
        result
      end

      def to_h
        row.to_h.merge(
          {
            status: result.success? ? 'success' : 'failure',
            errs: result.success? ? nil : result.for_csv
          }
        )
      end

      private

      attr_reader :row, :result
    end
  end
end
