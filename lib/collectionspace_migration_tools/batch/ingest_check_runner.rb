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
      def initialize(batch_id:, wait: 1.5, checks: 1, rechecks: 1)
        @id = batch_id
        @wait = wait
        @checks = checks
        @rechecks = rechecks
      end

      def call
        batch = yield(CMT::Batch.find(id))
        _up = yield(uploaded?(batch))
        prefix = yield(prefix(batch))
        client = yield(CMT::Build::S3Client.call)
        lister = yield(CMT::S3::BucketLister.new(client: client, prefix: prefix))
        listable = yield(CMT::Batch::IngestStatusChecker.call(lister: lister, wait: wait, checks: checks, rechecks: rechecks))
        batchdir = yield(dir(batch))
        reporter = yield(CMT::Ingest::Reporter.new(output_dir: batchdir, bucket_list: listable.objects))
        report = yield(CMT::Batch::PostIngestReporter.call(batch: batch, list: listable.objects, reporter: reporter))

        Success(report)
      end
      
      private

      attr_reader :id, :wait, :checks, :rechecks

      def dir(batch)
        dir = batch.dir
        return Failure("No batch dir found for batch #{id}") if dir.nil? || dir.empty?

        Success(dir)
      end

      def prefix(batch)
        prefix = batch.batch_prefix
        return Failure("No batch prefix found for batch #{id}") if prefix.nil? || prefix.empty?

        Success(prefix)
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

