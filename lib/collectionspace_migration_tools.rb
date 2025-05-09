# frozen_string_literal: true

require "cspace_hosted_instance_access"
require "dry/monads"
require "dry/monads/do"
require "pry"
require "zeitwerk"

# Main namespace
module CollectionspaceMigrationTools
  ::CMT = CollectionspaceMigrationTools

  class << self
    attr_reader :tunnel
    attr_reader :connection

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
      @config ||= CMT::Configuration.call
    end

    def client
      return @client if instance_variable_defined?(:@client)

      client = CMT::Client.call
      if client.success?
        @client = client.value!
        return @client
      end

      puts client.failure
      exit
    end

    # @param connection_obj [CMT::Connection]
    def connection=(connection_obj)
      return connection if connection&.open?

      @connection = connection_obj
    end

    def csid_cache
      return @csid_cache if instance_variable_defined?(:@csid_cache)

      csid_cache = CMT::Cache::Builder.call(:csid)
      if csid_cache.success?
        @csid_cache = csid_cache.value!
        return @csid_cache
      end

      puts csid_cache.failure
      exit
    end

    def get_csv_path(csv)
      config = CMT.config.client
      return get_full_path(csv) unless config.respond_to?(:ingest_dir)
      if ["~", "/"].any? { |char| csv.start_with?(char) }
        return get_full_path(csv)
      end

      File.join(config.ingest_dir, csv)
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

      puts refname_cache.failure
      exit
    end

    def safe_exit
      connection&.close
      tunnel&.close
      exit
    end

    # @param tunnel_obj [CMT::Tunnel]
    def tunnel=(tunnel_obj)
      return tunnel if tunnel&.open?

      @tunnel = tunnel_obj
    end
  end

  # to identify CMT processes in `top`, `ps`, etc.
  Process.setproctitle("CMT")

  private

  def get_full_path(csv)
    return File.expand_path(csv) if csv.start_with?("~")

    csv
  end
  module_function :get_full_path
end

CMT.loader
