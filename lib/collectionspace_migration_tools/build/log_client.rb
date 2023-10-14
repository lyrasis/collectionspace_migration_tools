# frozen_string_literal: true

require "aws-sdk-cloudwatchlogs"

module CollectionspaceMigrationTools
  module Build
    # Returns AWS CloudWatchLog client
    class LogClient
      include Dry::Monads[:result]
      include Dry::Monads::Do.for(:call)

      class << self
        def call
          new.call
        end
      end

      def initialize
        @profile = CMT.config.system.aws_profile
      end

      def call
        client = yield(create_client)
        _try = yield(try(client))

        Success(client)
      end

      private

      attr_reader :profile

      def create_client
        client = Aws::CloudWatchLogs::Client.new(
          profile: profile
        )
      rescue => err
        msg = "#{err.message} IN #{err.backtrace[0]}"
        Failure(CMT::Failure.new(context: "#{self.class.name}.#{__callee__}",
          message: msg))
      else
        Success(client)
      end

      def try(client)
        result = client.describe_log_groups(limit: 5)
      rescue => err
        msg = "#{err.message} IN #{err.backtrace[0]}"
        Failure(CMT::Failure.new(context: "#{self.class.name}.#{__callee__}",
          message: msg))
      else
        Success(result)
      end
    end
  end
end
