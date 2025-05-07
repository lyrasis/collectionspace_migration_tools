# frozen_string_literal: true

module CollectionspaceMigrationTools
  module TermManager
    class Instance
      attr_reader :id

      # @param id [String]
      # @param config [Hash]
      def initialize(id, config)
        @id = id
        @config = config
      end

      def client = @client ||= build_client

      private

      attr_reader :config

      def build_client
        setup_config
        CollectionSpace::Client.new(
          CollectionSpace::Configuration.new(**config)
        )
      end

      def setup_config
        if config.empty?
          @config = CHIA.client_config_for(id)
        elsif config.keys.length < 3
          @config = CHIA.client_config_for(id).merge(config)
        end
      end
    end
  end
end
