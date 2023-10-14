# frozen_string_literal: true

require "dry/validation"

module CollectionspaceMigrationTools
  module Validate
    # Abstract contract class in case any behavior needs to apply to all application contracts
    class ApplicationContract < Dry::Validation::Contract
      Dry::Validation.load_extensions(:monads)
    end
  end
end
