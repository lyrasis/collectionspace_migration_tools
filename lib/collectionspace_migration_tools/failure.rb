# frozen_string_literal: true

module CollectionspaceMigrationTools
  module Failure
    module_function

    # @param failobj [Dry::Monads::Failure]
    # @return [String]
    def for_csv(failobj)
      "ERROR: #{failobj.trace}: #{failobj.failure}"
    end

    # @param failobj [Dry::Monads::Failure]
    # @return [String]
    def to_s(failobj)
      <<~MSG
        ERROR in #{failobj.trace}
        MESSAGE:
        #{failobj.failure}
      MSG
    end
  end
end
