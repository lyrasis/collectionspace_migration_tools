# frozen_string_literal: true

require "dry/monads"
require "dry/monads/do"

module CollectionspaceMigrationTools
  module Csv
    # Handles spinning off record mapping for individual rows
    class BatchPreprocessor
      include Dry::Monads[:result]
      include Dry::Monads::Do.for(:call)

      class << self
        def call(handler:, first_row:, batch:)
          new(handler: handler, first_row: first_row, batch: batch).call
        end
      end

      # @param handler [CollectionSpace::Mapper::DataHandler]
      # @param first_row [CSV::Row]
      # @param batch [CMT::Csv::BatchProcessor]
      def initialize(handler:, first_row:, batch:)
        @handler = handler
        @row = first_row
        @batch = batch
      end

      def call
        _headers_present = yield(CMT::Csv::MissingHeaderCheck.call(row))
        _required_present = yield(CMT::Csv::MissingRequiredFieldsCheck.call(
          handler, row
        ))
        _unknown = yield(CMT::Csv::UnknownFieldsCheck.call(handler, row))

        Success()
      end

      private

      attr_reader :handler, :row, :batch
    end
  end
end
