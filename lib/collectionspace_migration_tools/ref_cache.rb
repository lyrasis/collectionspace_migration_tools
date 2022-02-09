# frozen_string_literal: true

require 'collectionspace/refcache'
require 'dry/monads'

module CollectionspaceMigrationTools
  # Service object to return a CollectionSpace::RefCache object
  class RefCache
    class << self
      include Dry::Monads[:result]

      def call
        CMT::Client.call.bind do |client|
          build_cache_config(client).bind do |config|
            build_cache(client, config).fmap do |refcache|
              CMT::Cache::WithClient.new(client, refcache)
            end
          end
        end
      end

      private

      def build_cache(client, config)
        cache = CollectionSpace::RefCache.new(config: config, client: client)
      rescue StandardError => err
        Failure(CMT::Failure.new(context: "#{name}.#{__callee__}", message: err.message))
      else
        return Success(cache) if cache

        Failure(CMT::Failure.new(context: "#{name}.#{__callee__}", message: 'No CS RefCache object'))
      end
      
      def build_cache_config(client)
        config = {
          redis: 'redis://localhost:6379/1',
          domain: client.domain,
          error_if_not_found: false,
          lifetime: 60 * 60 * 24 * 7, #a week
          search_delay: 0,
          search_enabled: false,
          search_identifiers: false
        }
      rescue StandardError => err
        Failure(CMT::Failure.new(context: "#{name}.#{__callee__}", message: err.message))
      else
        return Success(config) if config

        Failure(CMT::Failure.new(context: "#{name}.#{__callee__}", message: 'No RefCache Configuration object'))
      end
    end
  end
end
