# frozen_string_literal: true

module CollectionspaceMigrationTools
  module TermManager
    class VersionLog
      # @param path [String]
      def initialize(path)
        @path = path
      end

      def missing? = @missing ||= !File.exist?(path)

      private

      attr_reader :path
    end
  end
end
