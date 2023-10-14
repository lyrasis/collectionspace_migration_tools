# frozen_string_literal: true

require "csv"
require "dry/monads"
require "dry/monads/do"

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
        @validator = validator
        @mapper = mapper
        @reporter = reporter
        @writer = writer
      end

      # @param row [CSV::Row] with headers
      def call(row)
        map_row(row).either(
          ->(successes) {
            successes.each do |success|
              writer.call(success.value!)
            end
          },
          ->(failure) { handle_failure(failure) }
        )
      end

      def to_monad
        Success(self)
      end

      private

      attr_reader :validator, :mapper, :reporter, :writer

      def handle_failure(failure)
        if failure.is_a?(CMT::Failure)
          reporter.report_failure(failure, self)
        else
          failure.each do |result|
            result.either(
              ->(success) { writer.call(success) },
              ->(failed) { reporter.report_failure(failed, self) }
            )
          end
        end
      end

      def map_row(row)
        validated = yield(validator.call(row))
        mapped = yield(mapper.call(validated))

        Success(mapped)
      end
    end
  end
end
