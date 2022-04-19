# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'
require 'pry'
require 'zeitwerk'

# Main namespace
module CollectionspaceMigrationTools
  ::CMT = CollectionspaceMigrationTools

  class << self
    def loader
      @loader ||= setup_loader
    end

    private def setup_loader
              @loader = Zeitwerk::Loader.for_gem
              @loader.enable_reloading
              @loader.setup
              @loader
            end

    def reload!
      @loader.reload
    end
    
    def config
      @config ||= CMT::Configuration.new
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

    def connection
      @connection
    end
    
    # @param connection_obj [CMT::Connection]
    def connection=(connection_obj)
      return connection if connection && connection.open?
      
      @connection = connection_obj
    end

    def csid_cache
      return @csid_cache if instance_variable_defined?(:@csid_cache)
      
      csid_cache = CMT::Cache::Builder.call(:csid)
      if csid_cache.success?
        @csid_cache = csid_cache.value!
        return @csid_cache
      end

      puts csid_cache.failure.to_s
      exit
    end

    def domain
      @domain ||= client.domain
    end
    
    def refname_cache
      return @refname_cache if instance_variable_defined?(:@refname_cache)
      
      refname_cache = CMT::Cache::Builder.call(:refname)
      if refname_cache.success?
        @refname_cache = refname_cache.value!
        return @refname_cache
      end

      puts refname_cache.failure.to_s
      exit
    end

    def safe_exit
      connection.close if connection
      tunnel.close if tunnel
      exit
    end

    def tunnel
      @tunnel
    end
    
    # @param tunnel_obj [CMT::Tunnel]
    def tunnel=(tunnel_obj)
      return tunnel if tunnel && tunnel.open?
      
      @tunnel = tunnel_obj
    end
  end
end

CMT.loader
