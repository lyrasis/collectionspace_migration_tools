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

      # @param csv_path [String]
      # @param handler [CollectionSpace::Mapper::DataHandler]
      # @param first_row [CSV::Row]
      # @param row_processor [CMT::Csv::RowProcessor]
      # @param term_reporter [CMT::Csv::BatchTermReporter]
      def initialize(csv_path:, handler:, first_row:, row_processor:, term_reporter:)
        @csv_path = csv_path
        @handler = handler
        @first_row = first_row
        @row_processor = row_processor
        @term_reporter = term_reporter
      end

      def call
        _preprocessed = yield(preprocess)
        start_time = Time.now
        _processed = yield(process)
        elap = Time.now - start_time
        puts "Processing time: #{elap}"
        
        Success()
      end
      
      def preprocess
        CMT::Csv::BatchPreprocessor.call(handler: handler, first_row: first_row, batch: self)
      end

      def chunks
        SmarterCSV.process(
          csv_path, {
            chunk_size: CMT.config.system.csv_chunk_size,
            convert_values_to_numeric: false,
            strings_as_keys: true
          })
      end
      
      def process
        Parallel.map(chunks, in_processes: CMT.config.system.max_threads) do |chunk|
          worker(chunk)
        end
      rescue StandardError => err
          Failure(CMT::Failure.new(context: "#{self.class.name}.#{__callee__}", message: err))
      else
        term_reporter.deduplicate
        Success()
      end

      def worker(chunk)
        chunk.each{ |row| row_processor.call(row) }
      end

      def to_monad
        Success(self)
      end
      
      def to_s
        "<##{self.class}:#{self.object_id.to_s(8)} #{csv_path}>"
      end

      private
      
      attr_reader :csv_path, :handler, :first_row, :row_processor, :term_reporter
    end
  end
end
