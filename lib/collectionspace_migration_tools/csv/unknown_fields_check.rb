# frozen_string_literal: true

require 'dry/monads'

module CollectionspaceMigrationTools
  module Csv
    class UnknownFieldsCheck
      include Dry::Monads[:result]

      class << self
        def call(handler, row)
          self.new(handler, row).call
        end
      end
      
      def initialize(handler, row)
        @handler = handler
        @row = row.to_h
      end

      def call
        result = handler.check_fields(row)[:unknown_fields]
        return Success() if result.empty?

        warn("WARNING: #{result.length} unknown fields in data will be ignored: #{result.join(', ')}")
        return Success()
      end
      
      private

      attr_reader :handler, :row
    end
  end
end
