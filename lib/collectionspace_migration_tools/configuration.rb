# frozen_string_literal: true

require "dry/monads"
require "dry/monads/do"
require "fileutils"

module CollectionspaceMigrationTools
  class Configuration
    include Dry::Monads[:result]
    include Dry::Monads::Do.for(:derive_config)

    class << self
      def call(...)
        new(...).call
      end
    end

    attr_reader :client, :database, :system, :redis

    def initialize(
      client: nil,
      system: File.join(Bundler.root, "system_config.yml"),
      redis: File.join(Bundler.root, "redis.yml"),
      mode: :prod
    )
      @client = client
      @mode = mode
    end

    def call
      derive_config.either(
        ->(success) { handle_success(success) },
        ->(failure) { handle_failure(failure) }
      )
    end

    private

    attr_reader :mode

    def derive_config
      @system = yield CMT::Config::System.call
      @redis = yield CMT::Config::Redis.call
      instance = yield CMT::Parse::YamlConfig.call(client_path)
      @client = yield CMT::Config::Client.call(hash: instance[:client])
      @database = yield CMT::Config::Database.call(hash: instance[:database])

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
      current = File.read(File.expand_path(system.config_name_file))
      case current
      when "sample"
        File.join(Bundler.root, "sample_client_config.yml")
      else
        File.expand_path(
          File.join(system.client_config_dir, "#{current}.yml")
        )
      end
    end

    def handle_success(success)
      case mode
      when :prod
        self
      else
        Success(self)
      end
    end

    def handle_failure(failure)
      case mode
      when :prod
        puts("Could not create config.")
        puts failure
        puts("Exiting...")
        exit
      else
        Failure(failure)
      end
    end
  end
end
