# frozen_string_literal: true

require "time"

module CollectionspaceMigrationTools
  module Logs
    extend Dry::Monads[:result, :do]

    def client_response(client, command, params)
      response = client.send(command, params)
    rescue => err
      msg = "#{err.message} IN #{err.backtrace[0]}"
      Failure(
        CMT::Failure.new(
          context: "#{name}.#{__callee__}", message: msg
        )
      )
    else
      Success(response)
    end

    # @param datestr [String] in format "2023-10-31", "2023-10-31_23:59",
    #   "2023-10-31_23:59:06", or "2023-10-31_23:59:06.592"
    # @return [Integer] epoch-with-milliseconds date/time expression used in
    #   AWS log timestamps
    def timestamp_from_datestring(datestr)
      result = (Time.parse(datestr).to_f * 1000.0).to_i
    rescue => err
      msg = "#{err.message} IN #{err.backtrace[0]}"
      Failure(
        CMT::Failure.new(
          context: "#{name}.#{__callee__}", message: msg
        )
      )
    else
      Success(result)
    end

    # @param timestamp [Integer] epoch-with-milliseconds date/time
    #   expression used in AWS log timestamps
    # @return [String] human-readable date/time in machine-local timezone
    def datestring_from_timestamp(timestamp)
      result = Time.at(0, timestamp, :millisecond)
        .strftime("%Y-%m-%d_%H:%M:%S.%L")
    rescue => err
      msg = "#{err.message} IN #{err.backtrace[0]}"
      Failure(
        CMT::Failure.new(
          context: "#{name}.#{__callee__}", message: msg
        )
      )
    else
      Success(result)
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
