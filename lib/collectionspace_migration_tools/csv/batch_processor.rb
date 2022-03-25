# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'
require 'parallel'
require 'smarter_csv'

module CollectionspaceMigrationTools
  module Csv
    # Handles spinning off record mapping for individual rows
    class BatchProcessor
      include Dry::Monads[:result]
      include Dry::Monads::Do.for(:call)

      attr_reader :unknown_fields
      # @param csv_path [String]
      # @param handler [CollectionSpace::Mapper::DataHandler]
      # @param first_row [CSV::Row]
      # @param row_processor [CMT::Csv::RowProcessor]
      # @param reporter [CMT::Csv::Reporter]
      def initialize(csv_path:, handler:, first_row:, row_processor:, reporter:)
        @csv_path = csv_path
        @handler = handler
        @first_row = first_row
        @row_processor = row_processor
        @reporter = reporter
        @unknown_fields = []
      end

      def add_unknown_field(field)
        @unknown_fields << field
      end

      def call
        _preprocessed = yield(preprocess)

        Success()
      end
      
      def preprocess
        CMT::Csv::BatchPreprocessor.call(handler: handler, first_row: first_row, batch: self)
      end

      def process
        chunks = SmarterCSV.process(
          csv_path, {
            chunk_size: CMT.config.system.csv_chunk_size,
            convert_values_to_numeric: false,
            strings_as_keys: true
          })

        Parallel.map(chunks, in_processes: CMT.config.system.max_threads) do |chunk|
          worker(chunk)
        end

        reporter.close
      end

      def worker(chunk)
        chunk.each{ |row| row_processor.call(row) }
      end

      def to_monad
        puts "Returning monad of #{self}"
        Success(self)
      end
      
      def to_s
        "<##{self.class}:#{self.object_id.to_s(8)} #{csv_path}>"
      end

      private
      
      attr_reader :csv_path, :handler, :first_row, :row_processor, :reporter
    end
  end
end
