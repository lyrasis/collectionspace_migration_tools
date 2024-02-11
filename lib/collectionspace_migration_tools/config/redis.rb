# frozen_string_literal: true

module CollectionspaceMigrationTools
  module Config
    class Redis < CMT::Config::Section
      DEFAULT_PATH = File.join(Bundler.root, "redis.yml")

      # @param path [String]
      def initialize(path: DEFAULT_PATH)
        super
        @validator = CMT::Validate::ConfigRedisContract
      end
    end
  end
end
