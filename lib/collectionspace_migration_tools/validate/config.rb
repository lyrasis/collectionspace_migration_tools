# frozen_string_literal: true

require 'dry/monads'

module CollectionspaceMigrationTools
  module Validate
    class Config
      class << self
        include Dry::Monads[:result]

        def call(config_hash)
          validated = config_hash.keys.map{ |key| validate(config: config_hash, type: key) }
          return Success(config_hash) if validated.all?(&:success?)

          Failure(CMT::Failure.new(context: name, message: compile_error_messages(validated)))
        end

        private

        def compile_error_messages(arr)
          failures(arr).map{ |result| format_errors(result) }
                              .join('; ')
        end

        def failures(arr)
          arr.select(&:failure?)
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
