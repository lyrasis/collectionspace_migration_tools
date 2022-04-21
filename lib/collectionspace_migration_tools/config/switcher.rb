# frozen_string_literal: true

module CollectionspaceMigrationTools
  module Config
    # Copies specified .yml file from `repo_dir/config` to client_config.yml
    class Switcher
      include Dry::Monads[:result]
      include Dry::Monads::Do.for(:call)

      class << self
        def call(...)
          self.new(...).call
        end
      end
      
      def initialize(config_name)
        @target_path = File.join(Bundler.root, 'client_config.yml')
        @source_path = File.join(Bundler.root, 'config', "#{config_name}.yml")
      end

      def call
        _chk = yield(check_source_exists)
        _valid = yield(CMT::Configuration.new(client: source_path, check: true))
        _copy = yield(copy_source)

        Success()
      end
      
      private

      attr_reader :target_path, :source_path

      def check_source_exists
        return Success() if File.exists?(source_path)

        Failure("#{source_path} does not exist")
      end

      def copy_source
        FileUtils.cp(source_path, target_path)
      rescue StandardError => err
        msg = "#{err.message} IN #{err.backtrace[0]}"
        Failure(CMT::Failure.new(context: "#{self.class.name}.#{__callee__}", message: msg))
      else
        Success()
      end
    end
  end
end
