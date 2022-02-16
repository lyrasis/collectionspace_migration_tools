# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module CollectionspaceMigrationTools
  class Configuration
    include Dry::Monads[:result]
    include Dry::Monads::Do.for(:validated_config_data)

    attr_reader :client, :database, :redis
    
    def initialize(client: File.join(Bundler.root, 'client_config.yml'), redis: File.join(Bundler.root, 'redis.yml'))
      @client_path = client
      @redis_path = redis
      validated_config_data.either(
        ->(result){ build_config(result) },
        ->(result){ bad_config_exit(result) }
      )
    end

    private

    def bad_config_exit(result)
      puts('Could not create config.')
      puts("Error occurred in: #{result.context}")
      puts("Error message: #{result.message}")
      puts('Exiting...')
      exit
    end

    def build_config(result)
      result.each do |section, config_data|
        instance_variable_set("@#{section}".to_sym, section_struct(config_data))
      end
    end

    def combine_configs(hash_a, hash_b)
      hash_a.merge(hash_b)
    end
    
    def section_struct(config_data)
      keys = config_data.keys
      values = config_data.values
      Struct.new(*keys).new(*values)
    end

    def validated_config_data
      client_hash = yield(CMT::ConfigParser.call(@client_path))
      redis_hash = yield(CMT::ConfigParser.call(@redis_path))
      config_hash = combine_configs(client_hash, redis_hash)
      validated = yield(CMT::Validate::Config.call(config_hash))

      Success(validated)
    end
  end
end
