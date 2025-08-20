# frozen_string_literal: true

module CollectionspaceMigrationTools
  module TermManager
    class Instance
      attr_reader :id

      # @param id [String]
      # @param config [Hash]
      def initialize(id, config)
        @id = id
        @orig_config = config
      end

      def client = @client ||= build_client

      private

      attr_reader :orig_config

      def build_client
        CollectionSpace::Client.new(
          CollectionSpace::Configuration.new(**setup_config)
        )
      end

      def setup_config
        if orig_config.nil? || orig_config.empty?
          CHIA.client_config_for(id)
        elsif orig_config.keys.length < 3
          CHIA.client_config_for(id).merge(orig_config)
        else
          orig_config
        end
      end
    end
  end
end
