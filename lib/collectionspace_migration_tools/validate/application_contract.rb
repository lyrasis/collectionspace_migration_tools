# frozen_string_literal: true

require "dry/validation"

module CollectionspaceMigrationTools
  module Validate
    # Abstract contract class in case any behavior needs to apply to all
    # application contracts
    class ApplicationContract < Dry::Validation::Contract
      Dry::Validation.load_extensions(:monads)

      class << self
        def call(...)
          new.call(...).to_monad
        end
      end

      register_macro(:dir_exists) do
        full = File.expand_path(value)
        unless Dir.exist?(full)
          key.failure("#{full} does not exist")
        end
      end

      register_macro(:file_exists) do
        full = File.expand_path(value)
        unless File.exist?(full)
          key.failure("#{full} does not exist")
        end
      end
    end
  end
end
