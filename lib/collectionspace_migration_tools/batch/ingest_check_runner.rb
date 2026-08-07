# frozen_string_literal: true

module CollectionspaceMigrationTools
  module Batch
    class IngestCheckRunner
      include CMT::Batch::DataGettable
      include Dry::Monads[:result]
      include Dry::Monads::Do.for(:call)

      class << self
        def call(...)
          new(...).call
        end
      end

      # @param batch_id [String] batch id
      def initialize(batch_id:, wait: 1.5, checks: 1, rechecks: 1,
        autodelete: false)
        @id = batch_id
        @wait = wait
        @checks = checks
        @rechecks = rechecks
        @autodelete = autodelete
      end

      def call
        batch = yield CMT::Batch.find(id)
        _up = yield uploaded?(batch)
        client = yield CMT::Build::S3Client.call
        prefix = yield get_batch_data(batch, "prefix")
        lister = yield CMT::S3::BucketLister.new(
          client: client, prefix: prefix
        )
        bucket_objs = yield lister.call
        events = yield fast_importer_log_events(batch)

        if events.empty?
          return Failure("Ingest has not yet started for this batch.\n"\
                         "There may be S3 objects for another batch delaying "\
                         "the ingest of this batch. You can check the total "\
                         "number of objects in the bucket via the "\
                         "`thor bucket objects` command and compare the total "\
                         "object count to the number of objects uploaded.")
        end

        unless bucket_objs.empty?
          _statuscheck = yield CMT::Batch::IngestStatusChecker.call(
            lister: lister, wait: wait, checks: checks, rechecks: rechecks
          )
          bucket_objs = lister.objects
        end

        _post = yield CMT::Batch::PostIngestCheckRunner.call(
          batch: batch, bucket_list: bucket_objs, autodelete: autodelete
        )

        Success()
      end

      private

      attr_reader :id, :wait, :checks, :rechecks, :autodelete

      def uploaded?(batch)
        timestamp = batch.uploaded?
        if timestamp.nil? || timestamp.empty?
          return Failure("Batch #{id} has not been uploaded")
        end

        ct = batch.upload_oks
        if ct.nil? || ct.empty?
          Failure("No successful upload count found for batch #{id}")
        elsif ct == "0"
          Failure("No records were uploaded for ingest for batch #{id}")
        else
          Success()
        end
      end
    end
  end
end
