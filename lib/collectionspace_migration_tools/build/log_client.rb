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

        Success(client)
      rescue => err
        Failure(err.message)
      end

      def try(client)
        result = client.filter_log_events({
          log_group_name: CMT.config.client.log_group_name,
          limit: 1
        })

        Success(result)
      rescue => err
        Failure(err.message)
      end
    end
  end
end
