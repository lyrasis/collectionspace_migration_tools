# frozen_string_literal: true

module CollectionspaceMigrationTools
  module S3
    class BucketLister
      include Dry::Monads[:result]
      include Dry::Monads::Do.for(:call, :continuation, :process)

      class << self
        def call(...)
          self.new(...).call
        end
      end

      def initialize(client:, prefix: nil, max: 1000)
        @client = client
        @prefix = prefix
        @bucket = CMT.config.client.s3_bucket
        @max = max
        @opts = set_opts
        @objects = []
      end

      def call
        reset
        response = yield(get_response)
        _processed = yield(process(response))

        Success(objects)
      end

      def objects
        @objects.flatten
      end

      def reset
        @objects = []
      end

      def size
        objects.length
      end
      
      private

      attr_reader :client, :prefix, :bucket, :max, :opts

      def compile(response)
        @objects << response.contents.map(&:key)
      rescue StandardError => err
        msg = "#{err.message} IN #{err.backtrace[0]}"
        Failure(CMT::Failure.new(context: "#{self.class.name}.#{__callee__}", message: msg))
      else
        Success()
      end

      def continuation(token)
        c_opts = opts.merge({continuation_token: token})
        response = yield(get_response(c_opts))
        _processed = yield(process(response))

        Success()
      end
      
      def get_response(args = opts)
        response = client.list_objects_v2(**args)
      rescue StandardError => err
        msg = "#{err.message} IN #{err.backtrace[0]}"
        Failure(CMT::Failure.new(context: "#{self.class.name}.#{__callee__}", message: msg))
      else
        Success(response)
      end

      def process(response)
        yield(compile(response))
        yield(continuation(response.next_continuation_token)) if response.is_truncated

        Success()
      end
      
      def set_opts
        return {bucket: bucket, max_keys: max} unless prefix

        {bucket: bucket, max_keys: max, prefix: prefix}
      end
    end
  end
end
