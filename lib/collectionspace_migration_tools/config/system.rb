# frozen_string_literal: true

module CollectionspaceMigrationTools
  module Config
    class System < CMT::Config::Section
      DEFAULT_PATH = CMT::Config.file_path(:system)

      # @param path [String]
      def initialize(path: DEFAULT_PATH, hash: nil)
        super
        # If you change default values here, update sample_system_config.yml
        @default_values = {
          db_port: 5432,
          db_connect_host: "localhost",
          db_tunnel_connection_pause: 3,
          csv_chunk_size: 50,
          max_threads: 10,
          max_processes: 6,
          aws_profile: "collectionspace",
          aws_media_ingest_profile: "shared",
          cs_app_version: "8_2"
        }
        @pathvals = %i[client_config_dir config_name_file
          cspace_config_untangler_dir term_manager_config_dir]
        @validator = CMT::Validate::ConfigSystemContract
      end
    end
  end
end
