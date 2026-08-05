# frozen_string_literal: true

module CollectionspaceMigrationTools
  module Config
    # Return names of available configs
    class Lister
      include Dry::Monads[:result]
      include Dry::Monads::Do.for(:call)

      class << self
        def call(...)
          new.call(...)
        end
      end

      # @param type [Symbol] allowed values: :filename, :basename, :path
      def initialize(config_dir: CMT.config.system.client_config_dir)
        @config_dir = config_dir
      end

      def call(type: :filename)
        _type = yield(allowed_type?(type))

        case type
        when :filename
          result = yield(children)
        when :basename
          c = yield(children)
          result = yield(basenames(c))
        when :path
          c = yield(children)
          result = yield(paths(c))
        end

        Success(result.sort)
      end

      private

      attr_reader :config_dir

      def allowed_type?(type)
        return Success() if allowed_types.any?(type)

        Failure("type must be one of: #{allowed_types.join(", ")}")
      end

      def allowed_types
        %i[filename basename path]
      end

      def basenames(filenames)
        result = filenames.map { |fn| File.basename(fn, ".yml") }

        Success(result)
      rescue => err
        Failure(err.message)
      end

      def children
        result = Dir.new(config_dir)
          .children
          .select { |file| File.extname(file) == ".yml" }

        Success(result)
      rescue => err
        Failure(err.message)
      end

      def copy_source
        FileUtils.cp(source_path, target_path)

        Success()
      rescue => err
        Failure(err.message)
      end

      def paths(filenames)
        result = filenames.map { |fn| File.join(config_dir, fn) }

        Success(result)
      rescue => err
        Failure(err.message)
      end
    end
  end
end
