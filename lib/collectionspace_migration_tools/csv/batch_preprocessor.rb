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
        def call(handler:, first_row:, batch:)
          self.new(handler: handler, first_row: first_row, batch: batch).call
        end
      end

      # @param handler [CollectionSpace::Mapper::DataHandler]
      # @param first_row [CSV::Row]
      # @param batch [CMT::Csv::BatchProcessor
      def initialize(handler:, first_row:, batch:)
        @handler = handler
        @row = first_row
        @batch = batch
      end

      def call
        _headers_present = yield(CMT::Csv::MissingHeaderCheck.call(row))
        _required_present = yield(CMT::Csv::MissingRequiredFieldsCheck.call(handler, row))
        unknown = yield(CMT::Csv::UnknownFieldsCheck.call(handler, row))

        report_unknown_fields(unknown) if unknown
        
        Success()
      end
      
      private

      attr_reader :handler, :row, :batch

      def report_unknown_fields(fields)
        fields.each{ |field| batch.add_unknown_field(field) }
      end
    end
  end
end
