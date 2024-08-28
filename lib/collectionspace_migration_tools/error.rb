# frozen_string_literal: true

module CollectionspaceMigrationTools
  # Mixin module included in any application-specific error classes
  #
  # This allows each application-specific error to:
  #
  # - be subclassed to proper exception class in standard Ruby exception
  #   hierarchy
  # - be identified or rescued by standard Ruby exception
  #   hierarchy ancestor, OR by application-specific error status
  module Error; end

  class BatchConfigError < StandardError
    include Error
  end

  class NonExistentDirectorySpecifiedError < ArgumentError
    include Error

    def initialize(setting, path)
      msg = "The path specified for #{setting} does not exist: #{path}"
      super(msg)
    end
  end
end
