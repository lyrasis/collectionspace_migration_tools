# frozen_string_literal: true

module CollectionspaceMigrationTools
  module Logs
    # Returns the log group's log stream having the most recent
    #   `last_event_timestamp`, or nil if there are no log streams
    #   for the group
    class LastEventLogStream
      include CMT::Logs
      include Dry::Monads[:result]
      include Dry::Monads::Do.for(:call)

      class << self
        def call(...)
          self.new(...).call
        end
      end

      def initialize(client: CMT::Build::LogClient.call)
        @client = if client.is_a?(Aws::CloudWatchLogs::Client)
                    client
                  elsif client.is_a?(Dry::Monads::Success)
                    client.value!
                  elsif client.is_a?(Dry::Monads::Failure)
                    client.failure
                  else
                    raise "Unknown client class"
                  end
        @params = {
          log_group_name: CMT.config.client.log_group_name,
          order_by: "LastEventTime",
          descending: true,
          limit: 1
        }
      end

      # @return [Aws::CloudWatchLogs::Types::LogStream] wrapped in
      #   Dry::Monad::Success
      def call
        response = yield client_response(client, :describe_log_streams, params)
        stream = yield unpack(response)

        Success(stream)
      end

      private

      attr_reader :client, :params

      def unpack(response)
        stream = response.log_streams.first
      rescue => err
        msg = "#{err.message} IN #{err.backtrace[0]}"
        Failure(
          CMT::Failure.new(
            context: "#{name}.#{__callee__}", message: msg
          )
        )
      else
        Success(stream)
      end
    end
  end
end
