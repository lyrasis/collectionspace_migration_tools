# frozen_string_literal: true

require "dry/monads"

module CollectionspaceMigrationTools
  module Csv
    # Maps given row to CS XML
    class RowMapper
      include Dry::Monads[:result]

      def initialize(handler)
        @handler = handler
      end

      def call(row)
        result = map(row)
        return result if result.failure? # i.e. if sending handler.process barfs

        response = wrap_result(result)
        valid?(response) ? Success(response) : Failure(response)
      end

      def to_monad
        Success(self)
      end

      private

      attr_reader :handler

      def valid?(response)
        response.all? { |resp| resp.success? }
      end

      def map(row)
        result = handler.process(row)
      rescue => err
        Failure(CMT::Failure.new(context: "Handler.process", message: err))
      else
        Success(result)
      end

      def wrap_result(result)
        val = result.value!
        val_arr = val.is_a?(Array) ? val : [val]
        val_arr.map { |res| res.valid? ? Success(res) : Failure(res) }
      end
    end
  end
end
