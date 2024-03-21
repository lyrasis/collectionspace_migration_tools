# frozen_string_literal: true

module CollectionspaceMigrationTools
  module Batch
    # Updates upload-related fields in batches CSV
    class PostUploadReporter
      include Dry::Monads[:result]
      include Dry::Monads::Do.for(:do_reporting)
      include CMT::Batch::Reportable

      class << self
        def call(...)
          new(...).call
        end
      end

      def initialize(batch:, dir:, start_time:)
        @process_type = "uploading"
        @batch = batch
        @start_time = CMT::Logs.format_timestring(start_time)
        @dir = "#{CMT.config.client.batch_dir}/#{dir}"
        @report_path = "#{@dir}/upload_report.csv"
        @updated = {}
        @status = "WARN: Reporting did not complete successfully"
      end

      def call
        call_and_report
      end

      private

      def do_reporting
        _bs = yield report("batch_status", "uploaded", overwrite: true)
        _status = yield(report("uploaded?", Time.now.strftime("%F_%H_%M")))
        successes = yield(
          CMT::Batch::CsvRowCounter.call(
            path: report_path,
            field: "cmt_upload_status",
            value: "success"
          ))
        _successes = yield(report("upload_oks", successes))
        total = batch.map_oks.to_i
        failures = total - successes
        _failures = yield(report("upload_errs", failures))
        _prefix = yield(report("batch_prefix", batch.prefix))
        _starttime = yield(report("ingest_start_time", start_time))

        @status = "Reporting completed"
        Success()
      end

      attr_reader :process_type, :batch, :start_time, :dir, :report_path,
        :updated, :status
    end
  end
end
