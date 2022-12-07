# frozen_string_literal: true

require 'parallel'

module CollectionspaceMigrationTools
  module Media
    # Handles parallel processing of derivative checks
    class DerivCheckProcessor
      include Dry::Monads[:result]

      class << self
        def call(...)
          self.new(...).call
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
        puts 'Making API calls to check derivatives. This will take a long '\
          'time...'
        start_time = Time.now
        result = Parallel.map(chunks,
                     in_threads: CMT.config.system.max_threads) do |chunk|
          worker(chunk)
        end
        elap = Time.now - start_time
        puts "Threaded derivative checking time: #{elap}"
      rescue StandardError => err
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

      attr_reader :checker, :chunks

      def worker(chunk)
        chunk.map do |row|
          CMT::Media::DerivableData.new(
            blob: row,
            deriv: checker.call(blobcsid: row['blobcsid'])
          ).to_h
        end
      end

      # @param rows [Array<CSV::Row>]
      # @param checker [CMT::Media::DerivChecker]
      def get_derivable(rows, checker)
        result = rows.map do |row|
          CMT::Media::DerivableData.new(
            blob: row,
            deriv: checker.call(blobcsid: row['blobcsid'])
          ).to_h
        end
      rescue StandardError => err
        msg = "#{err.message} IN #{err.backtrace[0]}"
        Failure(CMT::Failure.new(
          context: "#{self.class.name}.#{__callee__}", message: msg
        ))
      else
        Success(result)
      end
    end
  end
end
