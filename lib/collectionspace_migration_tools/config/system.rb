# frozen_string_literal: true

module CollectionspaceMigrationTools
  module Config
    class System < CMT::Config::Section
      DEFAULT_PATH = CMT::Configuration.config_file_path(:system)

      # @param path [String]
      def initialize(path: DEFAULT_PATH, hash: nil)
        super
        # If you change default values here, update sample_system_config.yml
        @default_values = {
          db_port: 5432,
          db_connect_host: "localhost"
        }
        @pathvals = %i[client_config_dir config_name_file
          term_manager_config_dir]
        @validator = CMT::Validate::ConfigSystemContract
      end
    end
  end
end
