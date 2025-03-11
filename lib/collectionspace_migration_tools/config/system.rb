# frozen_string_literal: true

module CollectionspaceMigrationTools
  module Config
    class System < CMT::Config::Section
      DEFAULT_PATH = CMT::Configuration.config_file_path(:system)

      # @param path [String]
      def initialize(path: DEFAULT_PATH, hash: nil)
        super
        @pathvals = %i[client_config_dir config_name_file
                       term_manager_config_dir]
        @validator = CMT::Validate::ConfigSystemContract
      end
    end
  end
end
