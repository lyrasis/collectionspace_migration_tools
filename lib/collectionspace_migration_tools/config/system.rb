# frozen_string_literal: true

module CollectionspaceMigrationTools
  module Config
    class System < CMT::Config::Section
      DEFAULT_PATH = File.join(Bundler.root, "system_config.yml")

      # @param path [String]
      def initialize(path: DEFAULT_PATH)
        super
        @pathvals = %i[client_config_dir config_name_file]
        @validator = CMT::Validate::ConfigSystemContract
      end
    end
  end
end
