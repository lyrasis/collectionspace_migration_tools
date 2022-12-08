# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'
require 'parallel'
require 'smarter_csv'

module CollectionspaceMigrationTools
  module S3
    # Handles spinning off record uploading for individual rows
    class BatchUploader
      include Dry::Monads[:result]
      include Dry::Monads::Do.for(:call)

      def initialize(csv_path:, uploader:, reporter:)
        @csv_path = csv_path
        @uploader = uploader
        @reporter = reporter
      end

      def call
        start_time = Time.now
        _processed = yield(process)
        elap = Time.now - start_time
        puts "Upload time: #{elap}"
        puts "INFO: Results written to: #{reporter.path}"

        Success()
      end

      def to_monad
        Success(self)
      end

      def to_s
        "<##{self.class}:#{self.object_id.to_s(8)} #{csv_path}>"
      end

      private

      attr_reader :csv_path, :uploader, :reporter

      def chunks
        SmarterCSV.process(
          csv_path, {
            chunk_size: CMT.config.system.csv_chunk_size,
            convert_values_to_numeric: false,
            strings_as_keys: true
          })
      end

      def process
        puts "Uploading CS XML to S3..."
        Parallel.map(
          chunks, in_threads: CMT.config.system.max_threads
        ) do |chunk|
          worker(chunk)
        end
      rescue StandardError => err
        msg = "#{err.message} IN #{err.backtrace[0]}"
        Failure(
          CMT::Failure.new(
            context: "#{self.class.name}.#{__callee__}",
            message: msg
          )
        )
      else
        Success()
      end

      def worker(chunk)
        chunk.each{ |row| uploader.call(row) }
      end
    end
  end
end
