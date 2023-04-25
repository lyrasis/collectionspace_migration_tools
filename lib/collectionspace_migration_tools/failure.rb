# frozen_string_literal: true

module CollectionspaceMigrationTools
  class Failure
    attr_reader :context, :message

    def initialize(context:, message:)
      @context = context
      @message = message
    end

    def backtrace
      if message.respond_to?(:backtrace)
        message.backtrace
      else
        nil
      end
    end

    def for_csv
      "ERROR in #{context}: #{message}"
    end

    def to_s
      <<~MSG
         ERROR in #{context}
         MESSAGE:
         #{message}
      MSG
    end
  end
end
