# frozen_string_literal: true

module CollectionspaceMigrationTools
  module Batch
    # Updates ingest-related fields in batches CSV
    class PostIngestReporter
      include Dry::Monads[:result]
      include Dry::Monads::Do.for(:do_reporting)
      include CMT::Batch::Reportable

      class << self
        def call(...)
          self.new(...).call
        end
      end

      def initialize(batch:, list:, reporter:)
        @batch = batch
        @list = list
        @reporter = reporter
        @process_type = 'ingesting'
        @dir = "#{CMT.config.client.batch_dir}/#{batch.dir}"
        @report_path = "#{@dir}/ingest_report.csv"
        @updated = {}
        @status = 'WARN: Ingest reporting did not complete successfully'
      end

      def call
        call_and_report
      end
      
      private

      attr_reader :process_type, :batch, :list, :reporter, :report_path, :updated, :status
      
      def do_reporting
        _status = yield(report('ingest_done?', Time.now.strftime("%F_%H_%M")))
        uploaded_ct = yield(uploaded)
        failures = list.length
        _failures = yield(report('ingest_errs', failures))
        successes = uploaded_ct - failures
        _successes = yield(report('ingest_oks', successes))

        if failures > 0
          rpt = yield(reporter.call)
          puts "Wrote item level ingest report to: #{report_path}"
        end
        
        @status = 'Ingest reporting completed'
        Success()
      end

      def uploaded
        result = batch.upload_oks
        return Failure("#{self.class.name} cannot get number of uploaded records for #{id}") if result.nil? || result.empty?

        Success(result.to_i)
      end
    end
  end
end
