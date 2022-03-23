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

    def add_batch_config_path_option_to_client(result)
      return if result[:client].key?(:batch_config_path)

      result[:client][:batch_config_path] = nil
    end
    
    def bad_config_exit(result)
      puts('Could not create config.')
      puts("Error occurred in: #{result.context}")
      puts("Error message: #{result.message}")
      puts('Exiting...')
      exit
    end

    def build_config(result)
      add_batch_config_path_option_to_client(result)
      
      result.each do |section, config_data|
        instance_variable_set("@#{section}".to_sym, section_struct(config_data))
      end
      fix_config_paths
    end

    def create_subdirs
      %i[mapper_dir xml_dir].each do |subdir|
        updatemeth = "#{subdir}=".to_sym
        own_path = is_own_dir?(client.send(subdir))
        
        client.send(updatemeth, own_path) if own_path
        next if own_path
        
        path = "#{client.base_dir}/#{client.send(subdir)}"
        next if Dir.exists?(path)

        puts "Creating directory: #{path}"
        FileUtils.mkdir(path)
      end
    end

    def expand_subdir(subdir)
      File.expand_path(subdir)
    rescue StandardError
      false
    end
    
    def is_own_dir?(subdir)
      expanded = expand_subdir(subdir)
      return expanded unless expanded

      test =  Dir.exist?(expanded)
      return test unless test

      expanded
    end
    
    def expand_base_dir
      expanded = File.expand_path(client.base_dir).delete_suffix('/')
      client.base_dir = expanded
    end
    
    def fix_config_paths
      expand_base_dir
      create_subdirs
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
