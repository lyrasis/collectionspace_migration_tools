# frozen_string_literal: true

require 'base64'
require 'dry/monads'

module CollectionspaceMigrationTools
  module Xml
    # Base 64 hashed filenames for payloads to be transferred via S3
    class FileNamer
      include Dry::Monads[:result]
      
      SEPARATOR = '|'
      
      # @param svc_path [String]
      # @param action [String<'CREATE', 'UPDATE', 'DELETE'>]
      def initialize(svc_path:, action:)
        @svc_path = svc_path
        @action = action
      end

      # @param id [String]
      def call(id)
        Base64.urlsafe_encode64([svc_path, id, action].join(SEPARATOR))
      end

      def to_monad
        Success(self)
      end
      
      private
      
      attr_reader :svc_path, :action

    end
  end
end

