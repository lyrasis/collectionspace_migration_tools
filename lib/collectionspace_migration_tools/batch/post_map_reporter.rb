# frozen_string_literal: true

require "dry/monads"
require "dry/monads/do"

module CollectionspaceMigrationTools
  module Batch
    # Updates mapping-related fields in batches CSV
    class PostMapReporter
      include Dry::Monads[:result]
      include Dry::Monads::Do.for(:do_reporting)
      include CMT::Batch::Reportable

      class << self
        def call(...)
          new(...).call
        end
      end

      # @param batch [CMT::Batch::Batch]
      # @param dir [String]
      def initialize(batch:, dir:)
        @process_type = "mapping"
        @batch = batch
        @report_path = "#{dir}/mapper_report.csv"
        @dir = dir
        @updated = {}
        @status = "WARN: Reporting did not complete successfully"
      end

      def call
        call_and_report
      end

      private

      def count_xml_files
        result = Dir.new(dir)
          .children
          .count { |file| File.extname(file) == ".xml" }
      rescue => err
        msg = "#{err.message} IN #{err.backtrace[0]}"
        Failure(CMT::Failure.new(context: "#{self.class.name}.#{__callee__}",
          message: msg))
      else
        Success(result)
      end

      def do_reporting
        _mode = yield report("batch_mode", batch.batch_mode, overwrite: true)
        _bs = yield report("batch_status", "mapped", overwrite: true)
        _status = yield(report("mapped?", Time.now.strftime("%F_%H_%M")))
        _dir = yield(report("dir", File.basename(dir)))
        successes = yield(count_xml_files)
        _successes = yield(report("map_oks", successes))
        batch.rec_ct.to_i
        failures = yield(CMT::Batch::CsvRowCounter.call(path: report_path,
          field: "cmt_outcome", value: "failure"))
        _failures = yield(report("map_errs", failures))
        warns = yield(CMT::Batch::CsvRowCounter.call(path: report_path,
          field: "cmt_warnings"))
        _warns = yield(report("map_warns", warns))
        missing_term_report = "#{dir}/missing_terms.csv"
        if File.exist?(missing_term_report)
          missing_term_ct = yield(CMT::Batch::CsvRowCounter.call(path: missing_term_report))
        else
          missing_term_ct = 0
        end
        _missing_term = yield(report("missing_terms", missing_term_ct))

        @status = "Reporting completed"
        Success()
      end

      attr_reader :process_type, :batch, :dir, :report_path, :updated, :status
    end
  end
end
