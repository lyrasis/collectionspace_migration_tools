# frozen_string_literal: true

require "collectionspace/refcache"
require "dry/monads"
require "dry/monads/do"

module CollectionspaceMigrationTools
  module Cache
    # Service object to return a CollectionSpace::RefCache object
    class Builder
      class << self
        def call(arg)
          new.call(arg)
        end
      end

      include Dry::Monads[:result]
      # @todo specify Do.for(:call)
      include Dry::Monads::Do

      # @param cache_type [Symbol] the type of RefCache to return: :refname or :csid
      def call(cache_type)
        port = yield(get_port(cache_type))
        db = yield(get_db)
        cache_config = yield(build_cache_config(port, db))
        cache = yield(build_cache(cache_config))

        Success(cache)
      end

      private

      def build_cache(cache_config)
        cache = CollectionSpace::RefCache.new(config: cache_config)
      rescue => err
        Failure(CMT::Failure.new(context: "#{self.class}.#{__callee__}",
          message: err.message))
      else
        return Success(cache) if cache

        Failure(CMT::Failure.new(context: "#{self.class}.#{__callee__}",
          message: "No CS RefCache object"))
      end

      def build_cache_config(port, db)
        config = {
          redis: "redis://localhost:#{port}/#{db}",
          domain: CMT.domain,
          error_if_not_found: false,
          lifetime: nil
        }
      rescue => err
        Failure(CMT::Failure.new(context: "#{self.class}.#{__callee__}",
          message: err.message))
      else
        return Success(config) if config

        Failure(CMT::Failure.new(context: "#{self.class}.#{__callee__}",
          message: "No RefCache Configuration object"))
      end

      def get_db
        db = CMT.config.client.redis_db_number
        return Success(db) if db

        Failure(CMT::Failure.new(context: "#{self.class}.#{__callee__}",
          message: "Could not get Redis db for client"))
      end

      def get_port(cache_type)
        redis_config = CMT.config.redis
        key = "#{cache_type}_port".to_sym

        begin
          value = redis_config.send(key)
        rescue NoMethodError
          Failure(CMT::Failure.new(
            context: "#{self.class}.#{__callee__}",
            message: ":#{cache_type} is not a valid cache_type value. Use :refname or :csid"
          ))
        else
          return Success(value) if value

          Failure(CMT::Failure.new(context: "#{self.class}.#{__callee__}",
            message: "Could not get Redis port for #{cache_type}"))
        end
      end
    end
  end
end
