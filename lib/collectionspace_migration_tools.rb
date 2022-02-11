# frozen_string_literal: true

require 'zeitwerk'

Zeitwerk::Loader.for_gem.setup

# Main namespace
module CollectionspaceMigrationTools
  ::CMT = CollectionspaceMigrationTools

  class << self
    def config
      @config ||= CMT::Configuration.new('config.yml')
    end

    def client
      return @client if instance_variable_defined?(:@client)
      
      client = CMT::Client.call
      if client.success?
        @client = client.value!
        return @client
      end

      puts client.failure.to_s
      exit
    end

    def refcache
      return @refcache if instance_variable_defined?(:@refcache)
      
      refcache = CMT::RefCache.call
      if refcache.success?
        @refcache = refcache.value!
        return @refcache
      end

      puts refcache.failure.to_s
      exit
    end
  end
end

# Adding for benchmarking cache population
module CollectionSpace
  # patch in size
  class RefCache
    def size
      @cache.size
    end

    def reset
      @cache.reset
    end

    module Backend
      # patch in size
      class Redis
        def reset
          @c.flushdb
        end
        
        def size
          @c.dbsize
        end
      end
    end
  end
end
# End added for benchmarking

#pop = CMT::Cache::Populate.call(CMT::Database::Query.refnames)

