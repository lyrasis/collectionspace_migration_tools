# frozen_string_literal: true

require 'base64'
require 'dry/monads'

module CollectionspaceMigrationTools
  module Xml
    # Determines actual action to use in file name, based on given action and record status
    class ServicesApiActionChecker
      include Dry::Monads[:result]
      
      # @param action [String<'CREATE', 'UPDATE', 'DELETE'>]
      def initialize(action)
        @action = action
      end

      # @param response [CollectionSpace::Mapper::Response]
      def call(response)
        actual_action = determine_action(response)
        return Failure([:cannot_delete_new_record, response]) if actual_action == :error

        Success(actual_action)
      end

      def to_monad
        Success(self)
      end
      
      private
      
      attr_reader :action

      def create_action(status)
        return action if status == :new

        'UPDATE'
      end

      def delete_action(status)
        return action if status == :existing

        :error
      end

      def determine_action(response)
        status = response.record_status
        case action
        when 'CREATE'
          actual = create_action(status)
        when 'UPDATE'
          actual = update_action(status)
        when 'DELETE'
          actual = delete_action(status)
        end

        return action if actual == action
        return actual if actual == :error

        response.add_warning(warning(status, actual))
        actual
      end


      def update_action(status)
        return action if status == :existing

        'CREATE'
      end

      def warning(status, actual_action)
        {
          category: :services_api_transfer_action_mismatch,
          message: "API TRANSFER ACTION MISMATCH: Given: #{action}. Record status: #{status}. Will transfer as: #{actual_action}"
        }
      end
    end
  end
end

