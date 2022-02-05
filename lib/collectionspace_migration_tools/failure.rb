# frozen_string_literal: true

module CollectionspaceMigrationTools
  class Failure
    attr_reader :context, :message

    def initialize(context:, message:)
      @context = context
      @message = message
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
