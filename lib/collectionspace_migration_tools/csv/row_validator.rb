# frozen_string_literal: true

require 'dry/monads'

module CollectionspaceMigrationTools
  module Csv
    # Validates given row
    class RowValidator
      include Dry::Monads[:result]

      def initialize(handler, reporter)
        puts "Setting up #{self.class.name}..."
        @handler = handler
        @reporter = reporter
      end

      def call(row)
        result = validate(row)
        return result if result.failure? # i.e. if sending handler.validate barfs

        response = result.value!
        return Success(response) if response.valid?
        
        reporter.report_failure(response)
        Failure(response)
      end

      def to_monad
        Success(self)
      end
      
      private

      attr_reader :handler, :reporter

      def validate(row)
        result = handler.validate(row)
      rescue StandardError => err
        Failure(CMT::Failure.new(context: "Handler.validate", message: err.message))
      else
        Success(result)
      end
    end
  end
end
