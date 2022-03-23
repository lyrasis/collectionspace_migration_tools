# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module CollectionspaceMigrationTools
  module Csv
    # Handles spinning off record mapping for individual rows
    class BatchPreprocessor
      include Dry::Monads[:result]
      include Dry::Monads::Do.for(:call)

      class << self
        def call(handler:, first_row:)
          self.new(handler: handler, first_row: first_row).call
        end
      end

      # @param csv_path [String]
      # @param mapper [Hash] parsed JSON record mapper
      # @param row_processor [CMT::Csv::RowProcessor]
      def initialize(handler:, first_row:)
        @handler = handler
        @row = first_row
      end

      def call
        headers_present = yield(CMT::Csv::MissingHeaderCheck.call(row))

        Success()
      end
      
      attr_reader :handler, :row
      
      private

    end
  end
end
