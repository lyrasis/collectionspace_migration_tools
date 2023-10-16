# frozen_string_literal: true

require "csv"
require "dry/monads"
require "dry/monads/do"
require "parallel"
require "smarter_csv"

module CollectionspaceMigrationTools
  module Ingest
    # Handles extraction of exception messages from logs for objects still in
    #   bucket at end of ingest
    class ErrorMessageCompiler
      include Dry::Monads[:result]
      include Dry::Monads::Do.for(:call)

      class << self
        def call(...)
          new(...).call
        end
      end

      attr_reader :path

      # @param batch [CMT::Batch::Batch]
      # @param bucket_list [Array<String>] keys of objects still in S3 bucket
      def initialize(batch:, bucket_list:)
        @bucket_list = bucket_list
        return if bucket_list.empty?

        @batch = batch
      end

      def call
        return Success(nil) if bucket_list.empty?

        puts "Getting log messages for ingest errors..."

        keyevents = yield CMT::Batch.object_key_log_events(
          batch.id, bucket_list
        )
        errs = yield CMT::Batch.exception_log_events(batch.id)

        errs_by_request = errs.map do |event|
          e = CMT::Logs::Event.new(event, "Exception: ")
          [e.requestid, e.value]
        end.to_h

        matched = keyevents.map do |event|
          e = CMT::Logs::Event.new(event, "Object key: ")
          [e.value, errs_by_request[e.requestid]]
        end.to_h

        Success(matched)
      end

      def to_monad
        Success(self)
      end

      private

      attr_reader :batch, :bucket_list
    end
  end
end
