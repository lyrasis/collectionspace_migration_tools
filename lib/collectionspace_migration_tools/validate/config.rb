require 'dry/monads'

module CollectionspaceMigrationTools
  module Validate
    class Config
      extend Dry::Monads[:result]
      
      def self.call(config_hash)
        client = validate(config: config_hash, type: :client)
        db = validate(config: config_hash, type: :database)
        return Success(config_hash) if client.success? && db.success?

        Failure(CMT::Failure.new(context: name, message: compile_error_messages(client, db)))
      end

      private

      def self.compile_error_messages(client, db)
        failures(client, db).map{ |result| format_errors(result) }.join('; ')
      end
      
      def self.failures(client, db)
        [client, db].select{ |result| result.failure? }
      end

      def self.format_errors(result)
        result.failure.errors.messages.map{ |msg| "#{msg.path.join(', ')} #{msg.text}" }.join('; ')
      end
      
      def self.validate(config:, type:)
        klass = Kernel.const_get("CMT::Validate::Config#{type.capitalize}Contract")
        klass.new.(config[type]).to_monad
      end
      
    end
  end
end
