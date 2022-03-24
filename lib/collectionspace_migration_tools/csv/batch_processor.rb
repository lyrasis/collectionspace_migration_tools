# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'
require 'smarter_csv'

module CollectionspaceMigrationTools
  module Csv
    # Handles spinning off record mapping for individual rows
    class BatchProcessor
      include Dry::Monads[:result]
      include Dry::Monads::Do.for(:preprocess)

      attr_reader :unknown_fields
      # @param csv_path [String]
      # @param mapper [Hash] parsed JSON record mapper
      # @param row_processor [CMT::Csv::RowProcessor]
      def initialize(csv_path:, handler:, row_getter:, row_processor: )
        @csv_path = csv_path
        @handler = handler
        @first_row = row_getter.call.value!
        @row_processor = row_processor
        @unknown_fields = []
      end

      def add_unknown_field(field)
        @unknown_fields << field
      end
      
      def preprocess
        CMT::Csv::BatchPreprocessor.call(handler: handler, first_row: first_row, batch: self)
      end
      
      private
      
      attr_reader :csv, :handler, :first_row, :row_processor
    end
  end
end
