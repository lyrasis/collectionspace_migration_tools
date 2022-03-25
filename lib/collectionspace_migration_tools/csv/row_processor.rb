# frozen_string_literal: true

require 'csv'
require 'dry/monads'
require 'dry/monads/do'

module CollectionspaceMigrationTools
  module Csv
    # Handles converting single CSV row hash into DataRow
    class RowProcessor
      include Dry::Monads[:result]
      include Dry::Monads::Do.for(:call)
      
      # @param output_dir [String]
      # @param namer [CMT::Xml::FileNamer]
      # @param validator [CollectionSpace::Mapper::RowValidator]
      # @param mapper [CollectionSpace::Mapper::RowMapper]
      # @param reporter [CollectionSpace::Mapper::BatchReporter]
      def initialize(validator:, mapper:, reporter:, writer:)
        puts "Setting up #{self.class.name}..."
        @validator = validator
        @mapper = mapper
        @reporter = reporter
        @writer = writer
      end
      
      # @param row [CSV::Row] with headers
      def call(row)
        validated = yield(validator.call(row))
        mapped = yield(mapper.call(validated))
        written = yield(writer.call(mapped))
        reporter.report_success(written)
        
        Success(mapped)
      end

      def to_monad
        Success(self)
      end
      
      private
      
      attr_reader :validator, :mapper, :reporter, :writer

    end
  end
end

