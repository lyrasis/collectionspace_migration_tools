# frozen_string_literal: true

require 'collectionspace/refcache'
require 'dry/monads'

module CollectionspaceMigrationTools
  # Namespace and shared data/functions for the cache
  module Cache

    class << self
      include Dry::Monads[:result]

      def call
        CMT::Client.call.bind do |client|
          @client = client
          build_config.bind do |config|
            @config = config
            build_cache
          end
        end
      end

      private

      def build_cache
        cache = CollectionSpace::RefCache.new(config: @config, client: @client)
      rescue StandardError => err
        Failure(CMT::Failure.new(context: "#{name}.#{__callee__}", message: err.message))
      else
        return Success(cache) if cache

        Failure(CMT::Failure.new(context: "#{name}.#{__callee__}", message: 'No CS RefCache object'))
      end
      
      def build_config
        config = {
          domain: @client.domain,
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
    
    module_function

  end
end
