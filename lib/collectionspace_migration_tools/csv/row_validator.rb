# frozen_string_literal: true

require "dry/monads"

module CollectionspaceMigrationTools
  module Csv
    # Validates given row
    class RowValidator
      include Dry::Monads[:result]

      def initialize(handler)
        @handler = handler
      end

      def call(row)
        result = validate(row)
        # i.e. if sending handler.validate barfs
        return result if result.failure?

        response = result.value!
        response.valid? ? Success(response) : Failure(response)
      end

      def to_monad
        Success(self)
      end

      private

      attr_reader :handler

      def validate(row)
        result = handler.validate(row)
      rescue => err
        Failure(CMT::Failure.new(context: "Handler.validate",
          message: err.message))
      else
        Success(result)
      end
    end
  end
end
