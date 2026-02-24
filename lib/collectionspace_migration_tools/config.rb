# frozen_string_literal: true

module CollectionspaceMigrationTools
  module Config
    extend Dry::Monads[:result, :do]

    module_function

    DEFAULT_FILE_OR_DIR_NAMES = {
      system: "system_config.yml",
      redis: "redis.yml",
      term_manager: "term_manager"
    }

    # @param [:system, :redis, :term_manager]
    def file_path(type)
      envkey = "COLLECTIONSPACE_MIGRATION_TOOLS_#{type.upcase}_CONFIG"
      envpath = ENV[envkey]
      return envpath if envpath

      name = DEFAULT_FILE_OR_DIR_NAMES[type]
      dotfile = File.join(File.expand_path("~"), ".config",
        "collectionspace_migration_tools", name)
      return dotfile if File.exist?(dotfile)

      File.join(Bundler.root, name)
    end
  end
end
