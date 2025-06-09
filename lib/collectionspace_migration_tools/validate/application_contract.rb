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
        next if value.nil?

        full = File.expand_path(value)
        unless Dir.exist?(full)
          key.failure("#{full} does not exist")
        end
      end

      register_macro(:file_exists) do
        next if value.nil?

        full = File.expand_path(value)
        unless File.exist?(full)
          key.failure("#{full} does not exist")
        end
      end

      register_macro(:file_exists_or_gets_created) do
        next if value.nil?

        full = File.expand_path(value)
        create_file(full, key) unless File.exist?(full)
      end

      private

      def create_file(full_path, key)
        File.open(full_path, "w") { |file| file << "" }
      rescue
        key.failure("#{full} does not exist and cannot be created")
      end
    end
  end
end
