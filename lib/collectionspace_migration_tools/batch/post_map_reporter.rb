# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module CollectionspaceMigrationTools
  module Batch
    # Updates mapping-related fields in batches CSV
    class PostMapReporter
      include Dry::Monads[:result]
      include Dry::Monads::Do.for(:do_reporting)
      include CMT::Batch::Reportable

      class << self
        def call(...)
          self.new(...).call
        end
      end

      def initialize(batch:, dir:)
        @process_type = 'mapping'
        @batch = batch
        @report_path = "#{dir}/mapper_report.csv"
        @dir = dir
        @updated = {}
        @status = 'WARN: Reporting did not complete successfully'
      end

      def call
        call_and_report
      end
      
      private

      def count_xml_files
        result = Dir.new(dir)
          .children
          .select{ |file| File.extname(file) == '.xml' }
          .length
      rescue StandardError => err
        msg = "#{err.message} IN #{err.backtrace[0]}"
        Failure(CMT::Failure.new(context: "#{self.class.name}.#{__callee__}", message: msg))
      else
        Success(result)
      end

      def do_reporting
        _status = yield(report('mapped?', Time.now.strftime("%F_%H_%M")))
        _dir  = yield(report('dir', File.basename(dir)))
        successes = yield(count_xml_files)
        _successes = yield(report('map_oks', successes))
        total = batch.rec_ct.to_i
        failures = total - successes
        _failures = yield(report('map_errs', failures))
        warns = yield(CMT::Batch::CsvRowCounter.call(report_path, 'cmt_warnings'))
        _warns = yield(report('map_warns', warns))

        @status = 'Reporting completed'
        Success()
      end
      
      attr_reader :process_type, :batch, :dir, :report_path, :updated, :status
    end
  end
end
