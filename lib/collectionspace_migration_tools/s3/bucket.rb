# frozen_string_literal: true

module CollectionspaceMigrationTools
  module S3
    module Bucket
      extend Dry::Monads[:result, :do]

      module_function

      def batch_objects(id)
        batch = yield(CMT::Batch.find(id))
        client = yield(CMT::Build::S3Client.call)
        list = yield(CMT::S3::BucketLister.call(client: client,
          prefix: batch.prefix))

        Success(list)
      end

      def empty(batch_id = nil)
        objs = batch_id ? yield(batch_objects(batch_id)) : yield(objects)
        client = yield(CMT::Build::S3Client.call)
        emptied = yield(CMT::S3::Emptier.call(client: client, list: objs))

        Success(emptied)
      end

      def objects
        client = yield(CMT::Build::S3Client.call)
        list = yield(CMT::S3::BucketLister.call(client: client))

        Success(list)
      end
    end
  end
end
