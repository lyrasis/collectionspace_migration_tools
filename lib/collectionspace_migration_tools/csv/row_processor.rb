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
      def initialize(output_dir:, namer:, validator:, mapper:, reporter:)
        puts "Setting up #{self.class.name}..."
        @output_dir = output_dir
        @namer = namer
        @validator = validator
        @mapper = mapper
        @reporter = reporter
      end
      
      # @param row [CSV::Row] with headers
      def call(row)
        validated = yield(validator.call(row))
        mapped = yield(mapper.call(validated))
        reporter.report_success(mapped)
        
        Success(mapped)
      end

      def to_monad
        Success(self)
      end
      
      private
      
      attr_reader :output_dir, :namer, :validator, :mapper, :reporter

    end
  end
end

