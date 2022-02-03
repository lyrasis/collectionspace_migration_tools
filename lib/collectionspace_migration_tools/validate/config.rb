# frozen_string_literal: true

require 'dry/monads'

module CollectionspaceMigrationTools
  module Validate
    class Config
      class << self
        include Dry::Monads[:result]

        def call(config_hash)
          client = validate(config: config_hash, type: :client)
          db = validate(config: config_hash, type: :database)
          return Success(config_hash) if client.success? && db.success?

          Failure(CMT::Failure.new(context: name, message: compile_error_messages(client, db)))
        end

        private

        def compile_error_messages(client, db)
          failures(client, db).map{ |result| format_errors(result) }
                              .join('; ')
        end

        def failures(client, db)
          [client, db].select(&:failure?)
        end

        def format_errors(result)
          result.failure.errors.messages.map{ |msg| "#{msg.path.join(', ')} #{msg.text}" }
                .join('; ')
        end

        def validate(config:, type:)
          klass = Kernel.const_get("CMT::Validate::Config#{type.capitalize}Contract")
          klass.new.call(config[type]).to_monad
        end
      end
    end
  end
end
