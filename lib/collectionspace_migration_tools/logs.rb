# frozen_string_literal: true

require "time"

module CollectionspaceMigrationTools
  module Logs
    extend Dry::Monads[:result, :do]

    def client_response(client, command, params)
      response = client.send(command, params)

      Success(response)
    rescue => err
      Failure(err.message)
    end

    # @param datestr [String] in format "2023-10-31", "2023-10-31 23:59",
    #   "2023-10-31 23:59:06", or "2023-10-31 23:59:06.592"
    # @return [Integer] epoch-with-milliseconds date/time expression used in
    #   AWS log timestamps
    def self.timestamp_from_datestring(datestr)
      result = (Time.parse(datestr).to_f * 1000.0).to_i

      Success(result)
    rescue => err
      Failure(err.message)
    end

    # @param timestamp [Integer] epoch-with-milliseconds date/time
    #   expression used in AWS log timestamps
    # @return [String] human-readable date/time in machine-local timezone
    def self.datestring_from_timestamp(timestamp)
      result = CMT::Logs.format_timestring(
        Time.at(0, timestamp, :millisecond)
      )

      Success(result)
    rescue => err
      Failure(err.message)
    end

    def self.format_timestring(time)
      time.strftime("%Y-%m-%d %H:%M:%S.%L")
    end

    def setup_client(client)
      if client.is_a?(Aws::CloudWatchLogs::Client)
        client
      elsif client.is_a?(Dry::Monads::Success)
        client.value!
      elsif client.is_a?(Dry::Monads::Failure)
        client.failure
      else
        raise "Unknown client class"
      end
    end
  end
end
