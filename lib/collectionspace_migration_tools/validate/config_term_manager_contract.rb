# frozen_string_literal: true

require "dry/validation"

module CollectionspaceMigrationTools
  module Validate
    class ConfigTermManagerContract < CMT::Validate::ApplicationContract
      TERM_LOAD_MODES = %w[additive exact].freeze

      params do
        required(:instances).filled(:hash)
        required(:version_log).filled(:string)
        required(:initial_term_list_load_mode).filled(:string)
        optional(:term_list_sources).maybe(:array)
        optional(:authority_sources).maybe(:array)
        optional(:initial_term_list_load_mode_overrides).maybe(:array)
      end

      rule(:initial_term_list_load_mode) do
        next if TERM_LOAD_MODES.include?(value)

        key.failure("must be one of: #{term_load_modes}")
      end

      private

      def term_load_modes = TERM_LOAD_MODES.join(", ")
    end
  end
end
