# frozen_string_literal: true

module CollectionspaceMigrationTools
  module Logs
    class LogstreamReport
      include Dry::Monads[:result]
      include Dry::Monads::Do.for(:call)
      include CMT::Logs

      class << self
        def call(...)
          new(...).call
        end
      end

      # @param start_events_per_stream [Integer]
      # @param end_events_per_stream [Integer]
      def initialize(start_events_per_stream, end_events_per_stream, outpath)
        @start_events_per_stream = start_events_per_stream
        @end_events_per_stream = end_events_per_stream
        @outpath = outpath
        @log_group_name = CMT.config.client.log_group_name
      end

      # @return [Dry::Monad::Result]
      # Writes the following to the given file:
      #
      # - Header with log stream name
      # - The first n events for the stream
      # - The last n events for the stream
      def call
        client = yield CMT::Build::LogClient.call
        streams = yield CMT::Logs::GetLogstreams.call(:asc)
        file = File.open(outpath, "w")
        streams.each { |stream| report(client, stream, file) }
        file.close
        Success()
      end

      private

      attr_reader :start_events_per_stream, :end_events_per_stream, :outpath,
        :log_group_name

      def report(client, stream, file)
        file << "========================================\n"
        file << "LOGSTREAM: #{stream.log_stream_name}\n"
        file << "========================================\n\n"

        if start_events_per_stream > 0
          get_start_events(client, stream).events.each do |event|
            file << event.message
            file << "\n"
          end
          file << if end_events_per_stream > 0
            "\n[...]\n"
          else
            "\n"
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
