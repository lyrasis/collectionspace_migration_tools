# frozen_string_literal: true

require "forwardable"

module CollectionspaceMigrationTools
  module Logs
    # Wrapper around Aws::CloudWatchLogs::Types::FilteredLogEvent class that
    #   adds message parsing
    class Event
      extend Forwardable

      attr_reader :category, :requestid, :value

      def_delegators :@event, :log_stream_name, :timestamp, :message

      def initialize(event, valprefix)
        @event = event
        @valprefix = valprefix
        @parts = message.chomp.split("\t")
        @category = @parts[0]
        @requestid = @parts[2]
        @value = @parts[3].delete_prefix(valprefix)
      end
    end
  end
end
