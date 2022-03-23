# frozen_string_literal: true

require 'psych'
require 'dry/monads'

module CollectionspaceMigrationTools
  module Parse
    class YamlConfig
      class << self
        include Dry::Monads[:result]

        def call(config_path)
          read(File.expand_path(config_path)).bind do |str|
            parse(str)
          end
        end

        private

        def parse(yaml)
          parsed = Psych.load(yaml, symbolize_names: true)
        rescue StandardError => err
          msg = "YAML could not be parsed: #{err.message}"
          Failure(CMT::Failure.new(context: "#{name}.#{__callee__}", message: msg))
        else
          Success(parsed)
        end

        def read(config_path)
          yaml_string = File.read(config_path)
        rescue StandardError => err
          Failure(CMT::Failure.new(context: "#{name}.#{__callee__}", message: err.message))
        else
          Success(yaml_string)
        end
      end
    end
  end
end
