# frozen_string_literal: true

module CollectionspaceMigrationTools
  class Failure
    attr_reader :context, :message

    def initialize(context:, message:)
      @context = context
      @message = message
    end
  end
end
