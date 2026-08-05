# frozen_string_literal: true

require "psych"
require "dry/monads"

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

          Success(parsed)
        rescue => err
          Failure("YAML could not be parsed: #{err.message}")
        end

        def read(config_path)
          yaml_string = File.read(config_path)

          Success(yaml_string)
        rescue => err
          Failure(err.message)
        end
      end
    end
  end
end
