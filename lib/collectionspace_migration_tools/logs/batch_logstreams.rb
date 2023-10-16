# frozen_string_literal: true

module CollectionspaceMigrationTools
  module Logs
    # Returns the logstreams for a batch.
    #
    # A logstream is determined to be for a batch when its
    #   `creation_time` is greater than or equal to 20 seconds prior
    #   to the `ingest_start_time` of the batch. If `ingest_complete_time` is
    #   populated for the batch, eligible logstreams will have a creation date
    #   less than its value.
    #
    # Identifying the logstreams associated with a batch allows us to
    #   narrow down `filter_log_events` used to extract exception information.
    class BatchLogstreams
      include CMT::Logs
      include CMT::Batch::DataGettable
      include Dry::Monads[:result]
      include Dry::Monads::Do.for(:call)

      class << self
        def call(...)
          new(...).call
        end
      end

      # @param batchid [String]
      def initialize(batchid)
        @batchid = batchid
        @params = {
          log_group_name: CMT.config.client.log_group_name,
          order_by: "LastEventTime",
          descending: true
        }
      end

      # @return [Array<Aws::CloudWatchLogs::Types::LogStream>] wrapped in
      #   Dry::Monad::Success
      def call
        client = yield CMT::Build::LogClient.call
        batch = yield CMT::Batch.find(batchid)
        starttime = yield get_batch_data(batch, "ingest_start_time")
        startts = yield CMT::Logs.timestamp_from_datestring(starttime)
        min_ts = startts - 20000
        max_ts = get_endtime(batch)

        response = yield client_response(client, :describe_log_streams, params)
        selector = build_selector(min_ts, max_ts)
        streams = yield select_eligible(response, selector)

        Success(streams)
      end

      private

      attr_reader :batchid, :params

      def get_endtime(batch)
        val = batch.ingest_complete_time
        return nil if val.nil? || val.empty?

        CMT::Logs.timestamp_from_datestring(val).value!
      end

      def build_selector(min_ts, max_ts)
        if max_ts
          ->(logstream) do
            creation = logstream.creation_time
            creation >= min_ts && creation <= max_ts
          end
        else
          ->(logstream) { logstream.creation_time >= min_ts }
        end
      end

      def select_eligible(response, selector)
        streams = streams_for_batch(response.log_streams, selector)
        return Success(streams) if response.last_page?

        get_from_next(response.next_page, selector, [streams])
      end

      def get_from_next(response, selector, streams)
        streams << streams_for_batch(response.log_streams, selector)
        return Success(streams.flatten) if response.last_page?

        get_from_next(response.next_page, selector, streams)
      end

      def streams_for_batch(arr, selector)
        arr.select { |stream| selector.call(stream) }
      end
    end
  end
end
