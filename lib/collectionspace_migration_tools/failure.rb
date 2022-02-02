module CollectionspaceMigrationTools
  class Failure
    attr_reader :context, :message
    def initialize(context:, message:)
      @context, @message = context, message
    end
  end
end
