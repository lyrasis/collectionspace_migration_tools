# frozen_string_literal: true

module CollectionspaceMigrationTools
  module Batch
    class PostIngestCheckRunner
      include CMT::Batch::DataGettable
      include Dry::Monads[:result]
      include Dry::Monads::Do.for(:call, :batch_end_time)

      class << self
        def call(...)
          new(...).call
        end
      end

      # @param batch [CMT::Batch::Batch]
      # @param bucket_list [Array]
      # @param autodelete [Boolean]
      def initialize(batch:, bucket_list:, autodelete: false)
        @batch = batch
        @bucket_list = bucket_list
        @autodelete = autodelete
      end

      def call
        donetime = yield batch_end_time
        errs = yield CMT::Ingest::ErrorMessageCompiler.call(
          batch: batch,
          bucket_list: bucket_list
        )
        batchdir = yield get_batch_data(batch, "dir")
        ingest_item_reporter = yield CMT::Ingest::Reporter.new(
          output_dir: batchdir, bucket_list: bucket_list, errs: errs
        )
        report_params = {
          batch: batch,
          list: bucket_list,
          reporter: ingest_item_reporter
        }
        report_params[:done_time] = donetime

        _ingest_report = yield CMT::Batch::PostIngestReporter.call(
          **report_params
        )

        rectype = yield get_batch_data(batch, "mappable_rectype")
        action = yield get_batch_data(batch, "action")

        unless dupe_checkable?(rectype, action)
          _dupe_reporter = yield CMT::Batch::DuplicateReporter.call(
            batch: batch
          )
          return Success()
        end

        obj = yield CMT::RecordTypes.to_obj(rectype)
        dupes = yield obj.duplicates
        _dupe_reporter = yield CMT::Batch::DuplicateReporter.call(
          batch: batch,
          data: dupes
        )

        if autodelete && dupes.num_tuples > 0
          _deleter = yield CMT::Duplicate::Deleter.call(
            rectype: rectype,
            batchdir: batchdir
          )
        end

        Success()
      end

      private

      attr_reader :batch, :bucket_list, :autodelete

      def completed_time?
        true if batch.ingest_complete_time && !batch.ingest_complete_time.empty?
      end

      def batch_end_time
        if completed_time?
          donetime = yield get_batch_data(batch, "ingest_complete_time")
        else
          st = yield get_batch_data(batch, "ingest_start_time")
          starttime = yield CMT::Logs.timestamp_from_datestring(st)

          events = yield CMT::Logs::BatchEventsFiltered.call(
            batchid: batch.id,
            pattern: "%Decoded batch\\x3A #{batch.id}\\s%",
            start_time: starttime
          )
          donetime = yield CMT::Logs.datestring_from_timestamp(
            events.last.timestamp
          )
        end

        Success(donetime)
      end

      def dupe_checkable?(rectype, action)
        return false unless action == "create"
        return false if uncheckable_rectypes.any?(rectype)

        true
      end

      def uncheckable_rectypes
        %w[authorityhierarchy nonhierarchicalrelationship objecthierarchy]
      end
    end
  end
end
