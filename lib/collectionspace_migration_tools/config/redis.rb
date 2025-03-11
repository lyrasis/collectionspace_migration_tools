# frozen_string_literal: true

module CollectionspaceMigrationTools
  module Config
    class Redis < CMT::Config::Section
      DEFAULT_PATH = CMT::Configuration.config_file_path(:redis)

      # @param path [String]
      def initialize(path: DEFAULT_PATH, hash: nil)
        super
        @validator = CMT::Validate::ConfigRedisContract
      end
    end
  end
end
