# frozen_string_literal: true

require 'dry/monads'

module CollectionspaceMigrationTools
  module VocabularyTerms
    # Handles converting single CSV row hash into DataRow
    class TermAdder
      include Dry::Monads[:result]

      # @param handler [CollectionSpace::Mapper::VocabularyTerms::Handler]
      # @param reporter [CMT::VocabularyTerms::AdderReporter]
      def initialize(handler:, reporter:)
        @handler = handler
        @reporter = reporter
      end

      # @param row [CSV::Row] with headers
      def call(row)
        add_term(row).either(
          ->(success) do
            reporter.report_success(row, success)
          end,
          ->(failure) do
            reporter.report_failure(row, failure)
          end
        )
      end

      def to_monad
        Success(self)
      end

      private

      attr_reader :handler, :reporter

      def add_term(row)
        handler.add_term(vocab: row['vocab'], term: row['term'])
      end
    end
  end
end
