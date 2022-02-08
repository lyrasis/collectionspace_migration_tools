# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module CollectionspaceMigrationTools
  class Configuration
    include Dry::Monads[:result]
    include Dry::Monads::Do.for(:validated_config_data)

    attr_reader :client, :database
    
    def initialize(config_path)
      @path = config_path
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
      puts('Please provide a valid config .yml file and try again. Exiting...')
      exit
    end

    def build_config(result)
      result.each do |section, config_data|
        instance_variable_set("@#{section}".to_sym, section_struct(config_data))
      end
    end

    def section_struct(config_data)
      keys = config_data.keys
      values = config_data.values
      Struct.new(*keys).new(*values)
    end

    def validated_config_data
      config_hash = yield(CMT::ConfigParser.call(@path))
      validated = yield(CMT::Validate::Config.call(config_hash))

      Success(validated)
    end
  end
end
