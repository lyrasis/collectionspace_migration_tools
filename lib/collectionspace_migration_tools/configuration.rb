# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'
require 'fileutils'

module CollectionspaceMigrationTools
  class Configuration
    include Dry::Monads[:result]
    include Dry::Monads::Do.for(:validated_config_data,
                                :get_client_config_hash)

    # If you change default values here, update sample_client_config.yml
    CLIENT_CONFIG_DEFAULTS = {
      client: {
        page_size: 50,
        cs_version: "7_0",
        batch_dir: "batch_data",
        auto_refresh_cache_before_mapping: true,
        clear_cache_before_refresh: true,
        csv_delimiter: ',',
        s3_region: 'us-west-2',
        s3_delimiter: '|',
        media_with_blob_upload_delay: 250,
        max_media_upload_threads: 5
      },
      database: {
        port: 5432,
        db_user: 'csadmin',
        db_connect_host: 'localhost'
      }
    }

    attr_reader :client, :database, :system, :redis

    def initialize(
      client: File.join(Bundler.root, 'client_config.yml'),
      system: File.join(Bundler.root, 'system_config.yml'),
      redis: File.join(Bundler.root, 'redis.yml'),
      check: false
    )
      @client_path = client
      @system_path = system
      @redis_path = redis
      @check = check
      @status = Success()

      validated_config_data.either(
        ->(result){ build_config(result) },
        ->(result){ handle_failure(result) }
      )
    end

    def to_monad
      status
    end

    private

    attr_reader :client_path, :system_path, :redis_path, :check, :status

    def add_media_blob_delay(result)
      key = :media_with_blob_upload_delay
      if result[:client].key?(key)
        val = result[:client][key]
        return if val == 0

        result[:client][key] = Rational("#{val}/1000").to_f
      else
        add_option_to_section(result, :client, :media_with_blob_upload_delay, 0)
      end
    end

    # Manipulate the config hash before converting to Structs
    def add_option_to_section(confighash, section, key, value)
      return if confighash[section].key?(key)

      confighash[section][key] = value
    end

    def bad_config_exit(result)
      puts('Could not create config.')
      puts("Error occurred in: #{result.context}")
      puts("Error message: #{result.message}")
      puts('Exiting...')
      exit
    end

    def build_config(result)
      add_option_to_section(result, :client, :batch_config_path, nil)
      add_option_to_section(result, :client, :auto_refresh_cache_before_mapping, false)
      add_option_to_section(result, :client, :clear_cache_before_refresh, false)

      base = File.expand_path(result[:client][:base_dir])
      add_option_to_section(result, :client, :batch_csv, File.join(base, 'batches.csv'))

      add_media_blob_delay(result)

      result.each do |section, config_data|
        instance_variable_set("@#{section}".to_sym, section_struct(config_data))
      end
      fix_config_paths
    end

    def handle_failure(failure)
      if check
        @status = Failure(failure)
      else
        bad_config_exit(failure)
      end
    end

    def handle_subdirs
      %i[mapper_dir batch_dir].each do |subdir|
        CMT::ConfigSubdirectoryHandler.call(config: client, setting: subdir)
      end
    end

    def expand_base_dir
      expanded = File.expand_path(client.base_dir).delete_suffix('/')
      client.base_dir = expanded
    end

    def expand_other_paths
      %i[batch_csv batch_config_path].each do |key|
        val = client.send(key)
        next unless val

        meth = "#{key}=".to_sym
        client.send(meth, File.expand_path(val))
      end
    end

    def fix_config_paths
      expand_base_dir
      expand_other_paths
      handle_subdirs
    end

    # @param base [Hash] literal config from YAML file
    def apply_client_config_defaults(base)
      [:client, :database].each do |section|
        CLIENT_CONFIG_DEFAULTS[section].each do |setting, value|
          next if base[section].key?(setting)

          base[section][setting] = value
        end
      end
    rescue StandardError => err
      Failure(CMT::Failure.new(
        context: "#{name}.#{__callee__}", message: err.message
      ))
    else
      Success()
    end

    def get_client_config_hash
      base = yield CMT::Parse::YamlConfig.call(client_path)
      _defaults_applied = yield apply_client_config_defaults(base)

      Success(base)
    end

    def section_struct(config_data)
      keys = config_data.keys
      values = config_data.values
      Struct.new(*keys).new(*values)
    end

    def validated_config_data
      client_hash = yield(get_client_config_hash)
      system_hash = yield(CMT::Parse::YamlConfig.call(system_path))
      redis_hash = yield(CMT::Parse::YamlConfig.call(redis_path))
      config_hash = client_hash.merge(system_hash).merge(redis_hash)
      validated = yield(CMT::Validate::Config.call(config_hash))

      Success(validated)
    end
  end
end
