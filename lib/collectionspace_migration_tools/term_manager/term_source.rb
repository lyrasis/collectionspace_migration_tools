# frozen_string_literal: true

module CollectionspaceMigrationTools
  module TermManager
    class TermSource
      # @param path [String]
      def initialize(path)
        @path = path
      end

      def type = @type || get_type

      private

      attr_reader :path

      def get_type
        return :authority if CMT.config
          .term_manager.authority_sources
          .include?(path)

        :term_list
      end
    end
  end
end
