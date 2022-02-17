# frozen_string_literal: true

require 'zeitwerk'

Zeitwerk::Loader.for_gem.setup

# Main namespace
module CollectionspaceMigrationTools
  ::CMT = CollectionspaceMigrationTools

  class << self
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
  end
end


#pop = CMT::Cache::Populate.call(CMT::Database::Query.refnames)

