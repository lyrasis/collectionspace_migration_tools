# frozen_string_literal: true

require "csv"
require "dry/monads"
require "dry/monads/do"
require "parallel"
require "smarter_csv"

module CollectionspaceMigrationTools
  module Ingest
    # Handles writing ingest report CSV
    class Reporter
      include Dry::Monads[:result]
      include Dry::Monads::Do.for(:report)

      class << self
        def call(...)
          new(...).call
        end
      end

      attr_reader :path

      # @param output_dir [String] directory for batch
      # @param bucket_list [Array<String>] keys of objects still in S3 bucket
      # @param errs [nil, Hash{String=>String}] where keys are S3 object keys of
      #   objects in bucket, and values are error messages from logs
      def initialize(output_dir:, bucket_list:, errs:)
        @bucket_list = bucket_list
        return if bucket_list.empty?

        @errs = errs
        batchdir = CMT.config.client.batch_dir
        @path = File.join(batchdir, output_dir, "ingest_report.csv")
        @source = File.join(batchdir, output_dir, "upload_report.csv")
        CMT::Csv::FirstRowGetter.call(source).bind do |row|
          @fields = [row.headers, "CMT_ingest_status",
            "CMT_ingest_message"].flatten
        end
        CSV.open(path, "wb") { |csv| csv << @fields }
      end

      def call
        if bucket_list.empty?
          report_and_stop
        elsif fields
          report
        else
          Failure("#{self.class.name} could not get headers from source file: #{source}")
        end
      end

      def to_monad
        Success(self)
      end

      private

      attr_reader :fields, :bucket_list, :errs, :source

      def report_and_stop
        puts "No ingest failures. Skipping writing a report."
        Success()
      end

      def report
        _processed = yield(process)

        Success(path)
      end

      def chunks
        SmarterCSV.process(
          source, {
            chunk_size: CMT.config.system.csv_chunk_size,
            convert_values_to_numeric: false,
            strings_as_keys: true
          }
        )
      end

      def process
        puts "Processing/writing ingest report..."

        Parallel.map(chunks,
          in_threads: CMT.config.system.max_threads) do |chunk|
          worker(chunk)
        end
      rescue => err
        msg = "#{err.message} IN #{err.backtrace[0]}"
        Failure(CMT::Failure.new(context: "#{self.class.name}.#{__callee__}",
          message: msg))
      else
        Success()
      end

      def process_row(row)
        status = bucket_list.any?(row["cmt_s3_key"]) ? "failure" : "success"
        row["CMT_ingest_status"] = status
        row["CMT_ingest_message"] =
          errs[CMT::S3.obj_key_log_format(row["cmt_s3_key"])]
        row
      end

      def worker(chunk)
        processed = chunk.map { |row| process_row(row) }
        write_rows(processed)
      end

      def write_rows(rows)
        CSV.open(path, "a") do |csv|
          rows.each do |row|
            csv << row.fetch_values(*fields) { |_key| nil }
          end
        end
      end
    end
  end
end
