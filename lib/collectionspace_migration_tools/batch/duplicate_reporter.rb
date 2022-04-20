# frozen_string_literal: true

module CollectionspaceMigrationTools
  module Batch
    class DuplicateReporter
      include Dry::Monads[:result]
      include Dry::Monads::Do.for(:do_reporting, :uncheckable)
      include CMT::Batch::Reportable

      class << self
        def call(...)
          self.new(...).call
        end
      end

      def initialize(batch:, data: nil)
        @batch = batch
        @data = data
        @process_type = 'duplicate_checking'
        @dir = "#{CMT.config.client.batch_dir}/#{batch.dir}"
        @report_path = "#{@dir}/duplicate_report.csv"
        @updated = {}
        @status = Failure("WARN: #{process_type} reporting did not complete successfully")
      end

      def call
        if data
          call_and_report
        else
          call_and_report(:uncheckable)
        end
      end

      def to_monad
        status
      end
      
      private

      attr_reader :batch, :data, :process_type, :report_path, :updated, :status

      def do_reporting
        _status = yield(report('duplicates_checked?', Time.now.strftime("%F_%H_%M")))
        size = data.num_tuples
        _size = yield(report('duplicates', data.num_tuples))

        if size > 0
          reportpath = yield(CMT::Duplicate::CsvWriter.call(path: report_path, duplicates: data))
          puts "#{size} duplicate ids written to #{reportpath}"
        end
          
        # @todo write out csv report if any duplicates
        @status = Success("#{process_type} reporting completed")
        Success()
      end

      def uncheckable
        _chk = yield(report('duplicates_checked?', 'n/a'))
        _dupes = yield(report('duplicates', 'n/a'))

        @status = Success("Duplicates do not need to be checked")
        Success()
      end
    end
  end
end
