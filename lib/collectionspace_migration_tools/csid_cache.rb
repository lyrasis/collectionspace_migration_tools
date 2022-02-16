# frozen_string_literal: true

require 'collectionspace/refcache'
require 'dry/monads'

module CollectionspaceMigrationTools
  # Service object to return a CollectionSpace::RefCache object
  class CsidCache
    class << self
      include Dry::Monads[:result]

      # @param type [Symbol] :refnames or :csids
      def call
        build_cache_config(client).bind do |config|
          build_cache(config)
        end
      end

      private

      def build_cache(config)
        cache = CollectionSpace::RefCache.new(config: config, client: client)
      rescue StandardError => err
        Failure(CMT::Failure.new(context: "#{name}.#{__callee__}", message: err.message))
      else
        return Success(cache) if cache

        Failure(CMT::Failure.new(context: "#{name}.#{__callee__}", message: 'No CS RefCache object'))
      end
      
      def build_cache_config(client)
        config = {
          redis: "redis://localhost:6380/#{CMT.config.client.redis_db_number}",
          domain: CMT.domain,
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
