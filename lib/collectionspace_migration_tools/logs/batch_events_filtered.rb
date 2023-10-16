# frozen_string_literal: true

module CollectionspaceMigrationTools
  module Logs
    class BatchEventsFiltered
      include CMT::Logs
      include Dry::Monads[:result]
      include Dry::Monads::Do.for(:call)

      class << self
        def call(...)
          new(...).call
        end
      end

      # @param batchid [String]
      # @param pattern [String] filtern pattern for `filter_log_events` call;
      #   see https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/FilterAndPatternSyntax.html#regex-expressions
      # @param start_time [Integer]
      # @param end_time [Integer]
      # @param selector [nil, Lambda] takes single event object as argument;
      #   returns true or falsey
      def initialize(batchid:, pattern:, start_time: nil, end_time: nil,
        selector: nil)
        @batchid = batchid
        @pattern = pattern
        @start_time = start_time
        @end_time = end_time
        @selector = selector
      end

      def call
        client = yield CMT::Build::LogClient.call
        streams = yield CMT::Logs::BatchLogstreams.call(batchid)
        params = {
          log_group_name: CMT.config.client.log_group_name,
          filter_pattern: pattern,
          log_stream_names: streams.map(&:log_stream_name),
          start_time: start_time,
          end_time: end_time
        }.compact
        response = yield client_response(client, :filter_log_events, params)
        events = yield get_events(response, selector)

        Success(events)
      end

      private

      attr_reader :batchid, :pattern, :start_time, :end_time, :selector

      # @param response
      # @param selector [nil, Lambda] takes single event object as argument;
      #   returns true or falsey
      # @return [Array<Aws::CloudWatchLogs::Types::FilteredLogEvent>]
      def get_events(response, selector = nil)
        result = selected(response, selector)
        return Success(result) if response.last_page?

        multi_get(response.next_page, [result], selector)
      end

      # @param response
      # @param events [Array<Array<FilteredLogEvent>>]
      # @param selector [nil, Lambda] takes single event object as argument;
      #   returns true or falsey
      # @return [Array<Aws::CloudWatchLogs::Types::FilteredLogEvent>]
      def multi_get(response, events, selector = nil)
        events << selected(response, selector)
        return Success(events.flatten) if response.last_page?

        multi_get(response.next_page, events, selector)
      end

      def selected(response, selector = nil)
        return response.events unless selector

        response.events.select { |event| selector.call(event) }
      end
    end
  end
end
