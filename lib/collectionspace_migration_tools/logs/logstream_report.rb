# frozen_string_literal: true

module CollectionspaceMigrationTools
  module Logs
    class LogstreamReport
      include Dry::Monads[:result]
      include Dry::Monads::Do.for(:call)
      include CMT::Logs

      class << self
        def call(...)
          self.new(...).call
        end
      end

      # @param start_events_per_stream [Integer]
      # @param end_events_per_stream [Integer]
      def initialize(start_events_per_stream, end_events_per_stream, outpath)
        @start_events_per_stream = start_events_per_stream
        @end_events_per_stream = end_events_per_stream
        @outpath = outpath
        @client = setup_client(CMT::Build::LogClient.call)
        @log_group_name = CMT.config.client.log_group_name
      end

      # @return [Aws::CloudWatchLogs::Types::LogStream] wrapped in
      #   Dry::Monad::Success
      def call
        strparam = {
          log_group_name: log_group_name,
          order_by: "LastEventTime",
          descending: false
        }
        response = yield client_response(
          client, :describe_log_streams, strparam
        )
        file = File.open(outpath, "w")
        response.each { |page| report_page_streams(client, page, file) }
        file.close
        Success()
      end

      private

      attr_reader :client, :outpath, :log_group_name, :start_events_per_stream,
        :end_events_per_stream

      def report_page_streams(client, page, file)
        page.log_streams.each { |stream| report(client, stream, file) }
      end

      def report(client, stream, file)
        file << "========================================\n"
        file << "LOGSTREAM: #{stream.log_stream_name}\n"
        file << "========================================\n\n"

        if start_events_per_stream > 0
          get_start_events(client, stream).events.each do |event|
            file << event.message
            file << "\n"
          end
          if end_events_per_stream > 0
            file << "\n[...]\n"
          else
            file << "\n"
          end
        end

        if end_events_per_stream > 0
          get_end_events(client, stream).events
            .sort { |event| event.timestamp }
            .each do |event|
              file << event.message
              file << "\n"
            end
          file << "\n"
        end
      end

      def get_start_events(client, stream)
        param = {
          log_group_name: log_group_name,
          log_stream_name: stream.log_stream_name,
          start_from_head: true,
          limit: start_events_per_stream
        }
        client_response(client, :get_log_events, param).value!
      end

      def get_end_events(client, stream)
        param = {
          log_group_name: log_group_name,
          log_stream_name: stream.log_stream_name,
          start_from_head: false,
          limit: end_events_per_stream
        }
        client_response(client, :get_log_events, param).value!
      end
    end
  end
end
