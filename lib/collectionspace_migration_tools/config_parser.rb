require 'psych'
require 'dry/monads'

module CollectionspaceMigrationTools
  class ConfigParser
    extend Dry::Monads[:result]
    
    def self.call(config:)
      read(config: File.expand_path(config)).bind do |yaml_string|
        parse(yaml: yaml_string)
      end
    end

    private

    def self.parse(yaml:)
      parsed = Psych.load(yaml, symbolize_names: true)
    rescue StandardError, Psych::Exception => err
      Failure(CMT::Failure.new(context: "#{name}.#{__callee__}", message: err.message))
    else
      Success(parsed)
    end
     
    def self.read(config:)
      yaml_string = File.read(config)
    rescue StandardError => err
      Failure(CMT::Failure.new(context: "#{name}.#{__callee__}", message: err.message))
    else
      Success(yaml_string)
    end
  end
end
