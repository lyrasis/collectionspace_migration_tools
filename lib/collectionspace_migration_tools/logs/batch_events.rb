# frozen_string_literal: true

module CollectionspaceMigrationTools
  module Logs
    # Returns the number of log events matching "Decoded batch: #{batchid}"
    class BatchEvents
      include CMT::Logs
      include Dry::Monads[:result]
      include Dry::Monads::Do.for(:call, :multi_count)

      class << self
        def call(...)
          self.new(...).call
        end
      end

      # @param batchid [String]
      # @param client [CMT::Build::LogClient, nil]
      # @param since [Integer] will return events from this timestamp onward
      def initialize(batchid:, client: CMT::Build::LogClient.call)
        @client = setup_client(client)
        @params = {
          log_group_name: CMT.config.client.log_group_name,
          filter_pattern: "%Decoded batch\\x3A #{batchid}\\s%"
        }
      end

      def call
        response = yield client_response(client, :filter_log_events, params)
        events = yield get_events(response)

        Success(events)
      end

      private

      attr_reader :batchid, :client, :params

      def get_events(response)
        return Success(response.events) if response.last_page?

        multi_count(response.next_page, [response.events])
      end

      def multi_count(response, events)
        events << response.events
        return Success(events.flatten) if response.last_page?

        multi_count(response.next_page, events)
      end
    end
  end
end
