# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'
require 'fileutils'

module CollectionspaceMigrationTools
  class Configuration
    include Dry::Monads[:result]
    include Dry::Monads::Do.for(:validated_config_data)

    attr_reader :client, :database, :system, :redis
    
    def initialize(
      client: File.join(Bundler.root, 'client_config.yml'),
      system: File.join(Bundler.root, 'system_config.yml'),
      redis: File.join(Bundler.root, 'redis.yml')
    )
      @client_path = client
      @system_path = system
      @redis_path = redis
      
      validated_config_data.either(
        ->(result){ build_config(result) },
        ->(result){ bad_config_exit(result) }
      )
    end

    private

    attr_reader :client_path, :system_path, :redis_path

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
      
      base = File.expand_path(result[:client][:base_dir])
      add_option_to_section(result, :client, :batch_csv, File.join(base, 'batches.csv'))
      
      result.each do |section, config_data|
        instance_variable_set("@#{section}".to_sym, section_struct(config_data))
      end
      fix_config_paths
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

    def section_struct(config_data)
      keys = config_data.keys
      values = config_data.values
      Struct.new(*keys).new(*values)
    end

    def validated_config_data
      client_hash = yield(CMT::Parse::YamlConfig.call(client_path))
      system_hash = yield(CMT::Parse::YamlConfig.call(system_path))
      redis_hash = yield(CMT::Parse::YamlConfig.call(redis_path))
      config_hash = client_hash.merge(system_hash).merge(redis_hash)
      validated = yield(CMT::Validate::Config.call(config_hash))

      Success(validated)
    end
  end
end
