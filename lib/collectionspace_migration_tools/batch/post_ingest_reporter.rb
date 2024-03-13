# frozen_string_literal: true

module CollectionspaceMigrationTools
  module Batch
    # Updates ingest-related fields in batches CSV
    class PostIngestReporter
      include CMT::Batch::DataGettable
      include Dry::Monads[:result]
      include Dry::Monads::Do.for(:do_reporting)
      include CMT::Batch::Reportable

      class << self
        def call(...)
          new(...).call
        end
      end

      def initialize(batch:, list:, reporter:, done_time: nil)
        @batch = batch
        @list = list
        @done_time = done_time
        @reporter = reporter
        @process_type = "ingesting"
        @dir = "#{CMT.config.client.batch_dir}/#{batch.dir}"
        @report_path = "#{@dir}/ingest_report.csv"
        @updated = {}
        @status = "WARN: Ingest reporting did not complete successfully"
      end

      def call
        call_and_report
      end

      private

      attr_reader :process_type, :batch, :list, :done_time, :reporter,
        :report_path, :updated, :status

      def do_reporting
        _status = yield report("ingest_done?", Time.now.strftime("%F %H_%M"))

        if done_time
          _done = yield report(
            "ingest_complete_time", done_time, overwrite: true
          )
          start_time = yield get_batch_data(batch, "ingest_start_time")
          duration = yield get_duration(done_time, start_time)
          _dur = yield report("ingest_duration", duration, overwrite: true)
        end

        uploaded = yield get_batch_data(batch, "upload_oks")
        uploaded_ct = uploaded.to_i
        failures = list.length
        _failures = yield report("ingest_errs", failures)
        successes = uploaded_ct - failures
        _successes = yield report("ingest_oks", successes)

        if failures > 0
          _rpt = yield reporter.call
          puts "Wrote item level ingest report to: #{report_path}"
        end

        @status = "Ingest reporting completed"
        Success()
      end

      def get_duration(done_time, start_time)
        duration = Time.parse(done_time) - Time.parse(start_time)
        result = formatted_duration(duration)
      rescue => err
        msg = "#{err.message} IN #{err.backtrace[0]}"
        Failure(
          CMT::Failure.new(
            context: "#{name}.#{__callee__}", message: msg
          )
        )
      else
        Success(result)
      end

      def formatted_duration(total_seconds)
        # to avoid fractional seconds potentially compounding and messing up
        # seconds, minutes and hours
        total_seconds = total_seconds.round
        hours = total_seconds / (60 * 60)
        minutes = (total_seconds / 60) % 60
        seconds = total_seconds % 60
        [hours, minutes, seconds].map do |t|
          t.round.to_s.rjust(2, "0")
        end.join(":")
      end
    end
  end
end
