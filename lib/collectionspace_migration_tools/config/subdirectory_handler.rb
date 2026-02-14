# frozen_string_literal: true

require "fileutils"

module CollectionspaceMigrationTools
  module Config
    # Deals with the fact that I want to be able to specify:
    #
    # - the name of a directory relative to the given base directory; OR
    # - the full path to some directory outside the project base directory
    #
    # Updates the relevant setting to contain the full path:
    # - expanded if give path external to project dir
    # - base dir + sub dir if relative subdir given
    #
    # If subdirectory is given relative to project base directory, and does not
    # exist, the directory is created
    class SubdirectoryHandler
      include CMT::Config::DirSegmentReplaceable

      class << self
        # @param config [Hash]
        # @param setting [Symbol] the setting/method containing the subdirectory
        #   value
        def call(config:, setting:)
          new(config: config, setting: setting).call
        end
      end

      class NonExistentDirectorySpecifiedError < CMT::Error
        def initialize(setting, path)
          msg = "The path specified for #{setting} does not exist: #{path}"
          super(msg)
        end
      end

      # @param config [Hash]
      # @param setting [Symbol] the setting/method containing the subdirectory
      #   value
      def initialize(config:, setting:)
        return unless config[setting]

        @config = config
        @setting = setting
        @base = config[:base_dir]
        @value = replace_dir_segment(config[setting])
      end

      def call
        return unless config

        if File.absolute_path?(value)
          handle_absolute_path
        elsif value.start_with?("~")
          handle_relative_path
        else
          handle_subdir
        end
      end

      private

      attr_reader :config, :setting, :base, :value

      def create_directory(path)
        puts "Creating directory: #{path}"
        FileUtils.mkdir(path)
      end

      def handle_absolute_path
        return if Dir.exist?(value)

        raise NonExistentDirectorySpecifiedError.new(setting, value)
      end

      def handle_relative_path
        expanded = File.expand_path(value)
        unless Dir.exist?(expanded)
          raise NonExistentDirectorySpecifiedError.new(setting,
            expanded)
        end

        update_setting(expanded)
      end

      def handle_subdir
        path = "#{base}/#{value}"
        update_setting(path)
        return if Dir.exist?(path)
        return unless Dir.exist?(base)

        create_directory(path)
      end

      def update_setting(with)
        config[setting] = with
      end
    end
  end
end
