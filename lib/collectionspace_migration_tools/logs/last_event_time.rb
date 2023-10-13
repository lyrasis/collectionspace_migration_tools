# frozen_string_literal: true

module CollectionspaceMigrationTools
  module Logs
    # Returns the timestamp of last event for log group
    class LastEventTime
      include Dry::Monads[:result]
      include Dry::Monads::Do.for(:call)

      class << self
        def call
          self.new.call
        end
      end

      # @return [Aws::CloudWatchLogs::Types::LogStream] wrapped in
      #   Dry::Monad::Success
      def call
        stream = yield CMT::Logs::LastEventLogStream.call
        result = yield extract_time(stream)

        Success(result)
      end

      private

      attr_reader :client, :params

      def extract_time(stream)
        epoch_w_ms = stream.last_event_timestamp
        localtime = Time.at(0, epoch_w_ms, :millisecond)
        result = "#{localtime} (#{localtime.utc})"
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
    end
  end
end
