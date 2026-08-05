# frozen_string_literal: true

require "collectionspace/client"

module CollectionspaceMigrationTools
  # Service object returning CollectionSpace::Client object
  class Client
    class << self
      include Dry::Monads[:result]

      def call(include_deleted: false)
        build_client_config(include_deleted: include_deleted).bind do |config|
          build_client(config).bind do |client|
            verify(client)
          end
        end
      end

      private

      def build_client(config)
        client = CollectionSpace::Client.new(config)

        return Success(client) if client

        Failure("No CS Client object")
      rescue => err
        Failure(err.message)
      end

      def build_client_config(include_deleted:)
        config = CollectionSpace::Configuration.new(
          base_uri: CMT.config.client.base_uri,
          username: CMT.config.client.username,
          password: CMT.config.client.password,
          page_size: CMT.config.client.page_size,
          include_deleted: include_deleted
        )

        return Success(config) if config

        Failure("No CS Configuration object")
      rescue => err
        Failure(err.message)
      end

      def verify(client)
        result = client.can_authenticate?
        return Success(client) if result

        Failure("Client cannot authenticate to CS instance")
      rescue => err
        Failure(err.message)
      end
    end
  end
end
