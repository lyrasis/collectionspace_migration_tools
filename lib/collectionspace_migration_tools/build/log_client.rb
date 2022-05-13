# frozen_string_literal: true

require 'aws-sdk-cloudwatchlogs'

module CollectionspaceMigrationTools
  module Build
  # Returns AWS CloudWatchLog client
    class LogClient
      include Dry::Monads[:result]
      include Dry::Monads::Do.for(:call)
      
      class << self
        def call()
          self.new.call
        end
      end

      def initialize
        @key = CMT.config.client.s3_key
        @secret = CMT.config.client.s3_secret
        @region = CMT.config.client.s3_region
      end

      def call
        client = yield(create_client)
        _try = yield(try(client))

        Success(client)
      end
      
      private

      attr_reader :key, :secret, :region

      def create_client
        client = Aws::CloudWatchLogs::Client.new(
          access_key_id: key,
          secret_access_key: secret,
          region: region
        )
      rescue StandardError => err
        msg = "#{err.message} IN #{err.backtrace[0]}"
        Failure(CMT::Failure.new(context: "#{self.class.name}.#{__callee__}", message: msg))
      else
        Success(client)
      end

      def try(client)
        binding.pry
        result = client.get_bucket_location({bucket: bucket})
      rescue StandardError => err
        msg = "#{err.message} IN #{err.backtrace[0]}"
        Failure(CMT::Failure.new(context: "#{self.class.name}.#{__callee__}", message: msg))
      else
        Success(result)
      end
    end
  end
end
