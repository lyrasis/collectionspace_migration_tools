# frozen_string_literal: true

require "parallel"
require "smarter_csv"

module CollectionspaceMigrationTools
  module Csid
    # Handles parallel processing of CSID deletes
    class DeleteProcessor
      include Dry::Monads[:result]
      include Dry::Monads::Do.for(:call)

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
        thread_ct = CMT.config.system.max_threads

        puts "Making API calls to delete records (#{thread_ct} threads)..."
        start_time = Time.now
        chunks = yield CMT::Csv::Chunker.call(csv_path)
        result = Parallel.map(chunks.process,
          in_threads: thread_ct, progress: {
            format: "%t | %B | %c of %u | %a"
          }) do |chunk|
          worker(chunk)
        end
        elap = Time.now - start_time
        puts "CSID deletion time: #{elap}"

        Success(result.flatten)
      rescue => err
        Failure(err.message)
      end

      private

      attr_reader :deleter, :csv_path, :result_obj

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
