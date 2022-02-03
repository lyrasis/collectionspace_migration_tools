require 'psych'
require 'dry/monads'

module CollectionspaceMigrationTools
  class ConfigParser
    extend Dry::Monads[:result]
    
    def self.call(config_path)
      read(File.expand_path(config_path)).bind do |yaml_string|
        parse(yaml_string)
      end
    end

    private

    def self.parse(yaml)
      parsed = Psych.load(yaml, symbolize_names: true)
    rescue StandardError, Psych::Exception => err
      Failure(CMT::Failure.new(context: "#{name}.#{__callee__}", message: "YAML could not be parsed: #{err.message}"))
    else
      Success(parsed)
    end
     
    def self.read(config_path)
      yaml_string = File.read(config_path)
    rescue StandardError => err
      Failure(CMT::Failure.new(context: "#{name}.#{__callee__}", message: err.message))
    else
      Success(yaml_string)
    end
  end
end
