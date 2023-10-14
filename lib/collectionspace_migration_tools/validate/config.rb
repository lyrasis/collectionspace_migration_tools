# frozen_string_literal: true

require "dry/monads"

module CollectionspaceMigrationTools
  module Validate
    # Runs the individual validation contracts on the different config sections
    class Config
      class << self
        include Dry::Monads[:result]

        DEPRECATED_CLIENT_SETTINGS = %i[s3_region s3_key s3_secret]

        def call(config_hash)
          warn_of_deprecated_settings(config_hash)
          validated = config_hash.keys.map do |key|
            validate(config: config_hash, type: key)
          end
          return Success(config_hash) if validated.all?(&:success?)

          Failure(CMT::Failure.new(context: name,
            message: compile_error_messages(validated)))
        end

        private

        def compile_error_messages(arr)
          failures(arr).map { |result| format_errors(result) }
            .join("; ")
        end

        def failures(arr)
          arr.select(&:failure?)
        end

        def format_errors(result)
          result.failure.errors.messages.map do |msg|
            "#{msg.path.join(", ")} #{msg.text}"
          end
            .join("; ")
        end

        def validate(config:, type:)
          klass = Kernel.const_get("CMT::Validate::Config#{type.capitalize}Contract")
          klass.new.call(config[type]).to_monad
        end

        def warn_of_deprecated_settings(config_hash)
          deprecated = DEPRECATED_CLIENT_SETTINGS.intersection(
            config_hash[:client].keys
          )
          return if deprecated.empty?

          warn(deprecated_client_setting_msg)
        end

        def deprecated_client_setting_msg
          "DEPRECATED SETTINGS\ns3_region, s3_key, and s3_secret client "\
            "options are no longer supported. Please remove these from your "\
            ".yml client configs"
        end
      end
    end
  end
end
