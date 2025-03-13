# frozen_string_literal: true

module CollectionspaceMigrationTools
  module TermManager
    class Instance
      # @param id [String]
      # @param config [Hash]
      def initialize(id, config)
        @id = id
        @config = config
      end

      private

      attr_reader :config
    end
  end
end
