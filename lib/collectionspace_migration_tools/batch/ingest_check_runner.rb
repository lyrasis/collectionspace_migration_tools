# frozen_string_literal: true

module CollectionspaceMigrationTools
  module Batch
    class IngestCheckRunner
      include Dry::Monads[:result]
      include Dry::Monads::Do.for(:call)
      
      class << self
        def call(...)
          self.new(...).call
        end
      end

      # @param batch_id [String] batch id
      def initialize(batch_id:, wait: 1.5, checks: 1, rechecks: 1, autodelete: false)
        @id = batch_id
        @wait = wait
        @checks = checks
        @rechecks = rechecks
        @autodelete = autodelete
      end

      def call
        batch = yield(CMT::Batch.find(id))
        _up = yield(uploaded?(batch))
        prefix = yield(get_batch_data(batch, 'prefix'))
        client = yield(CMT::Build::S3Client.call)
        lister = yield(CMT::S3::BucketLister.new(client: client, prefix: prefix))
        listable = yield(CMT::Batch::IngestStatusChecker.call(lister: lister, wait: wait, checks: checks, rechecks: rechecks))
        batchdir = yield(get_batch_data(batch, 'dir'))
        ingest_item_reporter = yield(CMT::Ingest::Reporter.new(output_dir: batchdir, bucket_list: listable.objects))
        ingest_report = yield(CMT::Batch::PostIngestReporter.call(
          batch: batch,
          list: listable.objects,
          reporter: ingest_item_reporter
        ))

        rectype = yield(get_batch_data(batch, 'mappable_rectype'))
        action = yield(get_batch_data(batch, 'action'))
        
        unless dupe_checkable?(rectype, action)
          _dupe_reporter = yield(CMT::Batch::DuplicateReporter.call(batch: batch))
          return Success()
        end
        
        obj = yield(CMT::RecordTypes.to_obj(rectype))
        dupes = yield(obj.duplicates)
        _dupe_reporter = yield(CMT::Batch::DuplicateReporter.call(batch: batch, data: dupes))

        if autodelete && dupes.num_tuples > 0
          _deleter = yield(CMT::Duplicate::Deleter.call(rectype: rectype, batchdir: batchdir))
        end
        
        Success()
      end
      
      private

      attr_reader :id, :wait, :checks, :rechecks, :autodelete

      def dupe_checkable?(rectype, action)
        return false unless action == 'create'
        return false if uncheckable_rectypes.any?(rectype)

        true
      end

      def get_batch_data(batch, field)
        val = batch.send(field.to_sym)
        return Failure("No #{field} found for batch #{id}") if val.nil? || val.empty?

        Success(val)
      end

      def uncheckable_rectypes
        %w[authorityhierarchy nonhierarchicalrelationship objecthierarchy]
      end
      
      def uploaded?(batch)
        timestamp = batch.uploaded?
        return Failure("Batch #{id} has not been uploaded") if timestamp.nil? || timestamp.empty?

        ct = batch.upload_oks
        return Failure("No successful upload count found for batch #{id}") if ct.nil? || ct.empty?
        return Failure("No records were uploaded for ingest for batch #{id}") if ct == '0'

        Success()
      end
    end
  end
end

