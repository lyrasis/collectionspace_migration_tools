# frozen_string_literal: true

module CollectionspaceMigrationTools
  module Config
    class TermManager < CMT::Config::Section
      DEFAULT_PATH = CMT::Configuration.config_file_path(:term_manager)

      def initialize(hash:)
        super
        @default_values = {
          initial_term_list_load_mode: "additive",
          initial_term_list_load_mode_overrides: []
        }
        @validator = CMT::Validate::ConfigTermManagerContract
      end

      private

      def pre_manipulate
        return unless hash.key?(:authority_sources)

        hash[:authority_sources].transform_keys!(&:to_s)
      end
    end
  end
end
