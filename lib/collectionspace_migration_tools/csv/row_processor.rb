# frozen_string_literal: true

require 'csv'
require 'dry/monads'
require 'dry/monads/do'

module CollectionspaceMigrationTools
  module Csv
    # Handles converting single CSV row hash into DataRow
    class RowProcessor
      include Dry::Monads[:result]
      include Dry::Monads::Do.for(:map_row)
      
      # @param validator [CollectionSpace::Mapper::RowValidator]
      # @param mapper [CollectionSpace::Mapper::RowMapper]
      # @param reporter [CollectionSpace::Mapper::BatchReporter]
      # @param writer [CollectionSpace::XML::FileWriter]
      def initialize(validator:, mapper:, reporter:, writer:)
        puts "Setting up #{self.class.name}..."
        @validator = validator
        @mapper = mapper
        @reporter = reporter
        @writer = writer
      end
      
      # @param row [CSV::Row] with headers
      def call(row)
        map_row(row).either(
          ->(result){ writer.call(result) },
          ->(result){ reporter.report_failure(result, self) }
        )
      end

      def to_monad
        Success(self)
      end
      
      private
      
      attr_reader :validator, :mapper, :reporter, :writer

      def map_row(row)
        validated = yield(validator.call(row))
        mapped = yield(mapper.call(validated))

        Success(mapped)
      end
    end
  end
end

