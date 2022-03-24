# frozen_string_literal: true

require 'dry/monads'

module CollectionspaceMigrationTools
  module Csv
    class MissingRequiredFieldsCheck
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
        puts 'Checking for presence of required field(s)...'
        validated = handler.validate(row)
        return Success() if validated.valid?

        Failure(validated.errors.join('; '))
      end
      
      private

      attr_reader :handler, :row
    end
  end
end
