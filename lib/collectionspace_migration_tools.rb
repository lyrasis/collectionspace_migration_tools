# frozen_string_literal: true

require "cspace_hosted_instance_access"
require "dry/monads"
require "dry/monads/do"
require "pry"
require "zeitwerk"

# Main namespace
module CollectionspaceMigrationTools
  ::CMT = CollectionspaceMigrationTools

  # The CollectionSpace community-supported domain profiles and custom UI
  #   profiles known by this application
  KNOWN_CS_PROFILES = %w[anthro bonsai botgarden core fcart herbarium lhmc
    materials publicart
    ohc omca]

  at_exit do
    CMT.connection.close if CMT.connection&.open?
    CMT.tunnel&.close if CMT.tunnel&.open?
  end

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
    def set_connection(connection_obj)
      return connection if connection&.open?

      puts "New DB connection created for #{connection_obj.db}"
      @connection = connection_obj
    end

    def csid_cache = get_cache(:csid)

    def refname_cache = get_cache(:refname)

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

    # @param tunnel_obj [CMT::Tunnel]
    def set_tunnel(tunnel_obj)
      return tunnel if tunnel&.open?

      @tunnel = tunnel_obj
    end
  end

  # to identify CMT processes in `top`, `ps`, etc.
  Process.setproctitle("CMT")

  private

  def get_cache(type)
    iv = :"@#{type}_cache"
    return instance_variable_get(iv) if instance_variable_defined?(iv)

    cache = CMT::Cache::Builder.call(type)
    if cache.success?
      result = cache.value!
      instance_variable_set(iv, result)
      return result
    end

    puts cache.failure
    exit(1)
  end
  module_function :get_cache

  def get_full_path(csv)
    return File.expand_path(csv) if csv.start_with?("~")

    csv
  end
  module_function :get_full_path
end

CMT.loader
