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

      def initialize(batch:, list:, reporter:)
        @batch = batch
        @list = list
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

      attr_reader :process_type, :batch, :list, :reporter, :report_path,
        :updated, :status

      def do_reporting
        _status = yield(report("ingest_done?", Time.now.strftime("%F_%H_%M")))
        _done = yield(report("ingest_complete_time", done_time)) if done_time
        uploaded = yield get_batch_data(batch, "upload_oks")
        uploaded_ct = uploaded.to_i
        failures = list.length
        _failures = yield(report("ingest_errs", failures))
        successes = uploaded_ct - failures
        _successes = yield(report("ingest_oks", successes))

        if failures > 0
          _rpt = yield(reporter.call)
          puts "Wrote item level ingest report to: #{report_path}"
        end

        @status = "Ingest reporting completed"
        Success()
      end
    end
  end
end
