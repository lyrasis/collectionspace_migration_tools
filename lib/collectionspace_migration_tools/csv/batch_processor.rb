# frozen_string_literal: true

require "dry/monads"
require "dry/monads/do"
require "parallel"
require "smarter_csv"

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
      def initialize(csv_path:, handler:, first_row:, row_processor:,
        term_reporter:, output_dir:)
        @csv_path = csv_path
        @handler = handler
        @first_row = first_row
        @row_processor = row_processor
        @term_reporter = term_reporter
        @output_dir = output_dir
      end

      def call
        _preprocessed = yield(preprocess)

        start_time = Time.now
        chunks = yield CMT::Csv::Chunker.call(csv_path)
        _processed = yield process(chunks)
        elap = Time.now - start_time
        puts "Mapping time: #{elap}"
        puts "INFO: CS XML written to: #{output_dir}"

        if term_reporter.any_terms?
          _deduplicated = yield(term_reporter.deduplicate)
        else
          _delete_tr = yield(term_reporter.delete)
        end

        Success(output_dir)
      end

      def preprocess
        CMT::Csv::BatchPreprocessor.call(handler: handler,
          first_row: first_row, batch: self)
      end

      def process(chunks)
        puts "Mapping CSV rows to CS XML..."

        Parallel.map(chunks.process,
          in_processes: CMT.config.system.max_processes) do |chunk|
          worker(chunk)
        end

        Success()
      rescue => err
        Failure(err.message)
      end

      def worker(chunk)
        chunk.each { |row| row_processor.call(row) }
      end

      def to_monad
        Success(self)
      end

      def to_s
        "<##{self.class}:#{object_id.to_s(8)} #{csv_path}>"
      end

      private

      attr_reader :csv_path, :handler, :first_row, :row_processor,
        :term_reporter, :output_dir
    end
  end
end
