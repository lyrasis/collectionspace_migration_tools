# frozen_string_literal: true

module CollectionspaceMigrationTools
  module Batch
    class UploadRunner
      include Dry::Monads[:result]
      include Dry::Monads::Do.for(:call)

      class << self
        def call(...)
          self.new(...).call
        end
      end

      def initialize(batch_id:)
        @batch_id = batch_id
      end

      def call
        batch = yield CMT::Batch.find(batch_id)

        mapped = batch.mapped?
        if mapped.nil? || mapped.empty?
          return Failure(
            "Batch #{batch_id} is not mapped. You must map before uploading"
          )
        end

        uploadable = batch.map_oks
        if uploadable.nil? || uploadable.empty? || uploadable == '0'
          return Failure("No uploadable records for batch: #{batch_id}")
        end

        batch_dir = yield CMT::Batch.dir(batch_id)


        puts "\n\nUPLOADING"
        uploader = yield CMT::S3::UploaderPreparer.new(
          file_dir: batch_dir,
          rectype: batch.mappable_rectype
        ).call
        _uploaded = yield uploader.call
        report = yield CMT::Batch::PostUploadReporter.new(
          batch: batch,
          dir: batch_dir
        ).call

        Success(report)
      end

      private

      attr_reader :batch_id
    end
  end
end
