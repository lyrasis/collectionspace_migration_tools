# frozen_string_literal: true

require "parallel"

module CollectionspaceMigrationTools
  module Media
    # Handles parallel processing of derivative checks
    class DerivCheckProcessor
      include Dry::Monads[:result]

      class << self
        def call(...)
          new(...).call
        end
      end

      # @param checker [CMT::Media::DerivChecker]
      # @param rows [Array<CSV::Row>] CSV rows must have `blobcsid` column
      def initialize(checker:, rows:)
        @checker = checker
        size = CMT.config.system.csv_chunk_size
        @chunks = rows.each_slice(size).to_a
      end

      def call
        puts "Making API calls to check derivatives. This will take a long "\
          "time..."
        start_time = Time.now
        result = Parallel.map(chunks,
          in_threads: CMT.config.system.max_threads) do |chunk|
          worker(chunk)
        end
        elap = Time.now - start_time
        puts "Threaded derivative checking time: #{elap}"

        Success(result.flatten)
      rescue => err
        Failure(err.message)
      end

      private

      attr_reader :checker, :chunks

      def worker(chunk)
        chunk.map do |row|
          CMT::Media::DerivableData.new(
            blob: row,
            deriv: checker.call(blobcsid: row["blobcsid"])
          ).to_h
        end
      end

      # @param rows [Array<CSV::Row>]
      # @param checker [CMT::Media::DerivChecker]
      def get_derivable(rows, checker)
        result = rows.map do |row|
          CMT::Media::DerivableData.new(
            blob: row,
            deriv: checker.call(blobcsid: row["blobcsid"])
          ).to_h
        end

        Success(result)
      rescue => err
        Failure(err.message)
      end
    end
  end
end
