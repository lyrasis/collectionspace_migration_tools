# frozen_string_literal: true

require 'dry/monads'

module CollectionspaceMigrationTools
  module Csv
    class MissingHeaderCheck
      include Dry::Monads[:result]

      class << self
        def call(row)
          self.new(row).call
        end
      end
      
      def initialize(row)
        @row = row
      end

      def call
        puts 'Checking for missing headers...'
        missing_headers = row.headers.select(&:blank?)
        return Success(row) if missing_headers.empty?

        Failure("#{missing_headers.length} field(s) lack a header value")
      end
      
      private

      attr_reader :row
    end
  end
end
