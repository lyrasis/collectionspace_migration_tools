# frozen_string_literal: true

module CollectionspaceMigrationTools
  module Config
    # @abstract
    class Section
      include Dry::Monads[:result]
      include Dry::Monads::Do.for(:call)

      class << self
        def call(...)
          new(...).call
        end
      end

      def initialize(path: nil, hash: nil)
        @path = path ? File.expand_path(path) : nil
        @hash = hash
        @default_values = nil
        @validator = nil
        @pathvals = []
        @subdirvals = []
      end

      def call
        unless hash
          parsed = yield CMT::Parse::YamlConfig.call(path)
          @hash = parsed
        end
        apply_default_values if default_values
        _paths_expanded = yield expand_paths
        _validated = yield validate
        manipulate if private_methods.include?(:manipulate)
        struct = yield to_struct
        handle_subdirs(struct) unless subdirvals.empty?

        Success(struct)
      end

      private

      attr_reader :path, :hash, :default_values, :pathvals, :subdirvals,
        :validator

      def validate
        validator.call(hash).either(
          ->(success) { Success() },
          ->(failure) do
            prefix = "#{self.class.name} validation error(s): "
            errs = failure.errors(full: true).to_h.values.join("; ")
            Failure("#{prefix}#{errs}")
          end
        )
      end

      def add_option(setting, value)
        return if hash.key?(setting)

        hash[setting] = value
      end

      def apply_default_values
        default_values.each do |key, value|
          next if hash.key?(key)

          hash[key] = value
        end
      end

      def expand_paths
        pathvals.each { |pathkey| expand_path(pathkey) }
      rescue => err
        Failure(CMT::Failure.new(context: "#{self.class.name}.#{__callee__}",
          message: err.message))
      else
        Success()
      end

      def expand_path(key)
        val = hash[key]
        return unless val

        replacedval = if val.start_with?("thisappdir")
          val.sub("thisappdir", Bundler.root.to_s)
        else
          val
        end

        hash[key] = File.expand_path(replacedval)
          .delete_suffix("/")
      end

      def handle_subdirs(struct)
        subdirvals.each do |subdir|
          CMT::ConfigSubdirectoryHandler.call(config: struct, setting: subdir)
        end
      end

      def to_struct
        result = Struct.new(*hash.keys).new(*hash.values)
      rescue => err
        Failure(CMT::Failure.new(context: "#{self.class.name}.#{__callee__}",
          message: err.message))
      else
        Success(result)
      end
    end
  end
end
