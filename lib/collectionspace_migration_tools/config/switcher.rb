# frozen_string_literal: true

module CollectionspaceMigrationTools
  module Config
    # Copies specified .yml file from `repo_dir/config` to client_config.yml
    class Switcher
      include Dry::Monads[:result]
      include Dry::Monads::Do.for(:initialize, :call)

      class << self
        def call(...)
          new(...).call
        end
      end

      def initialize(client:)
        @client = client

        sysconfig = yield CMT::Config::System.call
        @target_path = sysconfig.config_name_file
        @source_path = File.join(sysconfig.client_config_dir, "#{client}.yml")
      end

      def call
        _chk = yield check_source_exists
        valid = yield CMT::Configuration.call(client: client, mode: :switch)
        _copy = yield set_source

        Success(valid)
      end

      private

      attr_reader :client, :target_path, :source_path

      def check_source_exists
        return Success() if File.exist?(source_path)

        current = File.read(target_path)
        Failure("#{source_path} does not exist. Still using #{current}")
      end

      def set_source
        File.open(target_path, "w") { |file| file << client }
      rescue => err
        msg = "#{err.message} IN #{err.backtrace[0]}"
        Failure(CMT::Failure.new(context: "#{self.class.name}.#{__callee__}",
          message: msg))
      else
        Success()
      end
    end
  end
end
