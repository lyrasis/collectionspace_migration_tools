# frozen_string_literal: true

module CollectionspaceMigrationTools
  module S3
    class Emptier
      include Dry::Monads[:result]
      include Dry::Monads::Do.for(:call)

      class << self
        def call(...)
          new(...).call
        end
      end

      def initialize(client:, list:,
        bucket: CMT.config.client.fast_import_bucket)
        @client = client
        @bucket = bucket
        @list = list
      end

      def call
        size = list.length
        return Success("No objects to delete") if size == 0

        puts "Deleting #{size} objects from S3"
        del_res = yield(do_deletes)
        _errs = yield(errored_chunks(del_res))

        Success("Done.")
      end

      private

      attr_reader :client, :bucket, :list

      def do_deletes
        result = chunks.map do |chunk|
          client.delete_objects({
            bucket: bucket,
            delete: {
              objects: chunk,
              quiet: false
            }
          })
        end
      rescue => err
        msg = "#{err.message} IN #{err.backtrace[0]}"
        Failure(CMT::Failure.new(context: "#{self.class.name}.#{__callee__}",
          message: msg))
      else
        Success(result)
      end

      def chunks
        list.each_slice(1000)
          .to_a
          .map { |obj_arr| hashify_object_chunk(obj_arr) }
      end

      def hashify_object_chunk(chunk)
        chunk.map { |obj| {key: obj} }
      end

      def errored_chunks(arr)
        result = arr.select { |response| !response.errors.empty? }
      rescue => err
        msg = "#{err.message} IN #{err.backtrace[0]}"
        Failure(CMT::Failure.new(context: "#{self.class.name}.#{__callee__}",
          message: msg))
      else
        result.empty? ? Success() : Failure(result)
      end
    end
  end
end
