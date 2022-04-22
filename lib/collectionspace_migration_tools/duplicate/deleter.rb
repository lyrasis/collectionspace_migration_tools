# frozen_string_literal: true

module CollectionspaceMigrationTools
  module Duplicate
    class Deleter
      include Dry::Monads[:result]
      include Dry::Monads::Do.for(:call, :duplicates, :rerun_deletes, :run_deletes)

      class << self
        def call(...)
          self.new(...).call
        end
      end

      def initialize(rectype:, batchdir: nil)
        @rectype = rectype
        @dupe_csv = batchdir.nil? ? nil : File.join(CMT.config.client.batch_dir, batchdir, 'duplicate_report.csv')
        @id = 'dd'
        @action = 'delete'
        @iteration = 1
      end

      def call
        _first_run = yield(run_deletes)

        until remaining.nil?
          rerun_deletes
        end

        puts 'No duplicates found'
        Success()
      end
      
      def to_monad
        Success(self)
      end
      
      private
      
      attr_reader :rectype, :dupe_csv, :id, :action, :iteration, :remaining

      def duplicates
        obj = yield(CMT::RecordTypes.to_obj(rectype))
        dupes = yield(obj.duplicates)

        Success(dupes)
      end

      def rerun_deletes
        source = yield(write_remaining_to_csv)
        @remaining = nil
        _del = yield(CMT::Batch.delete(id))
        _rerun = yield(run_deletes(source))

        Success()
      end
      
      def run_deletes(source_csv = dupe_csv)
        @iteration += 1
        if source_csv.nil?
          initial = yield(duplicates)
          @remaining = initial if initial.num_tuples > 0
          source_csv = yield(write_remaining_to_csv)
        end
        
        _add = yield(CMT::Batch::Add.call(id: id, csv: source_csv, rectype: rectype, action: action))
        _map = yield(CMT::Batch::MapRunner.call(batch_id: id))
        _upload = yield(CMT::Batch::UploadRunner.call(batch_id: id))
        _status = yield(CMT::Batch::IngestCheckRunner.call(
          batch_id: id,
          wait: 0.5,
          checks: 100,
          rechecks: 3,
          autodelete: true))
        dupes = yield(duplicates)
        @remaining = dupes if dupes.num_tuples > 0
        _cleared = yield(CMT::Batch.delete(id))
        
        Success()
      end

      def write_remaining_to_csv
        path = File.join(Bundler.root, 'tmp', "duplicate_report_#{iteration}.csv")
        CMT::Duplicate::CsvWriter.call(path: path, duplicates: remaining)
      end
    end
  end
end
