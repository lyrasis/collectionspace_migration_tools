# frozen_string_literal: true

require 'dry/monads'

module CollectionspaceMigrationTools
  module VocabularyTerms
    # Handles spinning off record mapping for individual rows
    class TermsCsvValidator
      include Dry::Monads[:result]

      class << self
        def call(...)
          self.new(...).call
        end
      end

      # @param row [CSV::Row] first row, with headers
      def initialize(row)
        @row = row
      end

      def call
        if row.key?('vocab') && row.key?('term')
          Success()
        else
          Failure('Terms ingest CSV must have headers: vocab, terms')
        end
      end

      private

      attr_reader :row
    end
  end
end
