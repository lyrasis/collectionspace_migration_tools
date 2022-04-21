# frozen_string_literal: true

module CollectionspaceMigrationTools
  module Config
    # Return names of available configs
    class Lister
      include Dry::Monads[:result]
      include Dry::Monads::Do.for(:call)

      class << self
        def call(...)
          self.new.call(...)
        end
      end

      # @param type [Symbol] allowed values: :filename, :basename, :path
      def initialize
        @config_dir = File.join(Bundler.root, 'config')
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

        Success(result)
      end
      
      private

      attr_reader :config_dir

      def allowed_type?(type)
        return Success() if allowed_types.any?(type)

        Failure("type must be one of: #{allowed_types.join(', ')}")
      end
      
      def allowed_types
        %i[filename basename path]
      end

      def basenames(filenames)
        result = filenames.map{ |fn| File.basename(fn, '.yml') }
      rescue StandardError => err
        msg = "#{err.message} IN #{err.backtrace[0]}"
        Failure(CMT::Failure.new(context: "#{self.class.name}.#{__callee__}", message: msg))
      else
        Success(result)
      end

      def children
        result = Dir.new(config_dir)
          .children
          .select{ |file| File.extname(file) == '.yml' }
      rescue StandardError => err
        msg = "#{err.message} IN #{err.backtrace[0]}"
        Failure(CMT::Failure.new(context: "#{self.class.name}.#{__callee__}", message: msg))
      else
        Success(result)
      end
      
      def copy_source
        FileUtils.cp(source_path, target_path)
      rescue StandardError => err
        msg = "#{err.message} IN #{err.backtrace[0]}"
        Failure(CMT::Failure.new(context: "#{self.class.name}.#{__callee__}", message: msg))
      else
        Success()
      end

      def paths(filenames)
        result = filenames.map{ |fn| File.join(config_dir, fn) }
      rescue StandardError => err
        msg = "#{err.message} IN #{err.backtrace[0]}"
        Failure(CMT::Failure.new(context: "#{self.class.name}.#{__callee__}", message: msg))
      else
        Success(result)
      end
    end
  end
end
