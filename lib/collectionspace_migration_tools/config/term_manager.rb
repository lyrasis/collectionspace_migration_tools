# frozen_string_literal: true

module CollectionspaceMigrationTools
  module Config
    class TermManager < CMT::Config::Section
      DEFAULT_PATH = CMT::Configuration.config_file_path(:term_manager)

      def initialize(hash:)
        super
        @default_values = {
          initial_term_list_load_mode: "additive"
        }
        @validator = CMT::Validate::ConfigTermManagerContract
      end
    end
  end
end
