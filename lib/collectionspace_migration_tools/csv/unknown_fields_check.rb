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
        puts 'Checking for unknown fields in data...'
        result = handler.check_fields(row)
        report_known(result)
        unknown = result[:unknown_fields]
        return Success() if unknown.empty?

        warn("\nWARNING: #{unknown.length} unknown fields in data will be ignored: #{unknown.join(', ')}")
        return Success(unknown)
      end
      
      private

      attr_reader :handler, :row

      def report_known(result)
        known = result[:known_fields]
        puts "INFO: #{known.length} known fields in data will be processed: #{known.join(', ')}"
      end
    end
  end
end
