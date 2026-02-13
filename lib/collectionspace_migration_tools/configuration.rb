# frozen_string_literal: true

require "fileutils"

module CollectionspaceMigrationTools
  class Configuration
    include Dry::Monads[:result]
    include Dry::Monads::Do.for(:add_config, :derive_config)

    DEFAULT_FILE_OR_DIR_NAMES = {
      system: "system_config.yml",
      redis: "redis.yml",
      term_manager: "term_manager"
    }
    class << self
      def call(...)
        new(...).call
      end

      def config_file_path(type)
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

    attr_reader :client, :database, :system, :redis, :term_manager

    def initialize(
      client: nil,
      system: self.class.config_file_path(:system),
      redis: self.class.config_file_path(:redis),
      mode: :prod
    )
      @client = client
      @system_path = system
      @redis_path = redis
      @mode = mode
    end

    def call
      derive_config.either(
        ->(success) { handle_success(success) },
        ->(failure) { handle_failure(failure) }
      )
    end

    def current_client = File.read(File.expand_path(system.config_name_file))

    def add_config(type, hash)
      if type == :term_manager
        @term_manager = yield CMT::Config::TermManager.call(hash: hash)
      end

      Success(self)
    end

    private

    attr_reader :system_path, :redis_path, :mode

    def derive_config
      @system = yield CMT::Config::System.call(path: system_path)
      @redis = yield CMT::Config::Redis.call(path: redis_path)

      unless mode == :check
        if client_path
          instance = yield CMT::Parse::YamlConfig.call(client_path)
          @client = yield CMT::Config::Client.call(hash: instance[:client])

          if @client.cspace_application_version
            @system.cspace_application_version = @client.cspace_application_version
          end
        end
      end
      @term_manager = nil

      Success()
    end

    def client_path
      return path_from_config_name_file if !client
      return client if ["~", "/"].any? { |char| client.start_with?(char) }

      File.expand_path(
        File.join(system.client_config_dir, "#{client}.yml")
      )
    end

    def path_from_config_name_file
      case current_client
      when ""
        nil
      when "sample"
        File.join(Bundler.root, "sample_client_config.yml")
      else
        File.expand_path(
          File.join(system.client_config_dir, "#{current_client}.yml")
        )
      end
    end

    def handle_success(success)
      return self if %i[check prod].include?(mode)

      Success(self)
    end

    def handle_failure(failure)
      return Failure(failure) unless %i[check prod].include?(mode)

      puts("Could not create config.")
      puts failure
      puts("Exiting...")
      exit
    end
  end
end
