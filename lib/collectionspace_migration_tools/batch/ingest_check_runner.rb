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
        batch = yield(CMT::Batch.find(id))
        _up = yield(uploaded?(batch))
        prefix = yield(get_batch_data(batch, "prefix"))
        client = yield(CMT::Build::S3Client.call)
        lister = yield(CMT::S3::BucketLister.new(client: client,
          prefix: prefix))

        end

        _post = yield CMT::Batch::PostIngestCheckRunner.call(
          batch: batch, bucket_list: bucket_objs
        )

        Success()
      end

      private

      attr_reader :id, :wait, :checks, :rechecks, :autodelete

      def uploaded?(batch)
        timestamp = batch.uploaded?
        return Failure("Batch #{id} has not been uploaded") if timestamp.nil? || timestamp.empty?

        ct = batch.upload_oks
        return Failure("No successful upload count found for batch #{id}") if ct.nil? || ct.empty?
        return Failure("No records were uploaded for ingest for batch #{id}") if ct == "0"

        Success()
      end
    end
  end
end
