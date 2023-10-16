# frozen_string_literal: true

require "parallel"
require "smarter_csv"

module CollectionspaceMigrationTools
  module Csid
    # Handles parallel processing of CSID deletes
    class DeleteProcessor
      include Dry::Monads[:result]

      class << self
        def call(...)
          new(...).call
        end
      end

      # @param deleter [CMT::Csid::Deleter]
      # @param csv_path [String] path to CSV with `csid` and `rectype` columns
      def initialize(deleter:, csv_path:, result_obj: CMT::Csid::DeleteResult)
        @deleter = deleter
        @csv_path = csv_path
        @result_obj = result_obj
      end

      def call
        puts "Making API calls to delete records..."
        start_time = Time.now
        result = Parallel.map(chunks,
          in_threads: CMT.config.system.max_threads) do |chunk|
          worker(chunk)
        end
        elap = Time.now - start_time
        puts "CSID deletion time: #{elap}"
      rescue => err
        msg = "#{err.message} IN #{err.backtrace[0]}"
        Failure(
          CMT::Failure.new(
            context: "#{self.class.name}.#{__callee__}",
            message: msg
          )
        )
      else
        Success(result.flatten)
      end

      private

      attr_reader :deleter, :csv_path, :result_obj

      def chunks
        SmarterCSV.process(
          csv_path, {
            chunk_size: CMT.config.system.csv_chunk_size,
            convert_values_to_numeric: false,
            strings_as_keys: true
          }
        )
      end

      def worker(chunk)
        chunk.map do |row|
          result_obj.new(
            row: row,
            result: deleter.call(row: row)
          )
        end
      end
    end
  end
end
