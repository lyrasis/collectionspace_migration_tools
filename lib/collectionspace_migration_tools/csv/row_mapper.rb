# frozen_string_literal: true

require 'dry/monads'

module CollectionspaceMigrationTools
  module Csv
    # Maps given row to CS XML
    class RowMapper
      include Dry::Monads[:result]

      def initialize(handler)
        puts "Setting up #{self.class.name}..."
        @handler = handler
      end

      def call(row)
        result = map(row)
        return result if result.failure? # i.e. if sending handler.process barfs

        response = result.value!
        response.valid? ? Success(response) : Failure(response)
      end

      def to_monad
        Success(self)
      end
      
      private

      attr_reader :handler

      def map(row)
        result = handler.process(row)
      rescue StandardError => err
        Failure(CMT::Failure.new(context: "Handler.process", message: err.message))
      else
        Success(result)
      end
    end
  end
end
