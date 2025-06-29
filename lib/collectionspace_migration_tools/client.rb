# frozen_string_literal: true

require "collectionspace/client"
require "dry/monads"

module CollectionspaceMigrationTools
  # Service object returning CollectionSpace::Client object
  class Client
    class << self
      include Dry::Monads[:result]

      def call
        build_client_config.bind do |config|
          build_client(config).bind do |client|
            verify(client)
          end
        end
      end

      private

      def build_client(config)
        client = CollectionSpace::Client.new(config)
      rescue => err
        Failure(CMT::Failure.new(context: "#{name}.#{__callee__}",
          message: err.message))
      else
        return Success(client) if client

        Failure(CMT::Failure.new(context: "#{name}.#{__callee__}",
          message: "No CS Client object"))
      end

      def build_client_config
        config = CollectionSpace::Configuration.new(
          base_uri: CMT.config.client.base_uri,
          username: CMT.config.client.username,
          password: CMT.config.client.password,
          page_size: CMT.config.client.page_size
        )
      rescue => err
        Failure(CMT::Failure.new(context: "#{name}.#{__callee__}",
          message: err.message))
      else
        return Success(config) if config

        Failure(CMT::Failure.new(context: "#{name}.#{__callee__}",
          message: "No CS Configuration object"))
      end

      def verify(client)
        result = client.can_authenticate?
        return Success(client) if result

        Failure(CMT::Failure.new(context: "#{name}.#{__callee__}",
          message: "Client cannot authenticate to CS instance"))
      rescue => err
        Failure(CMT::Failure.new(context: "#{name}.#{__callee__}",
          message: err.message))
      end
    end
  end
end
