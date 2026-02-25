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
    # @return [String]
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

    # @param config [CMT::Configuration, NilClass>
    # @return [Dry::Monads::Success<String>]
    def current_client_config_name(config = nil)
      system = if config
        config.system
      else
        yield CMT::Config::System.call
      end
      path = system.config_name_file
      content = File.read(path)
      if content.empty?
        return Failure(CMT::Failure.new(
          context: "#{self.class.name}.#{__callee__}",
          message: "No client config found. Try doing:\n"\
          "  thor config switch {yourconfigname}. "
        ))
      end

      Success(content)
    end
  end
end
