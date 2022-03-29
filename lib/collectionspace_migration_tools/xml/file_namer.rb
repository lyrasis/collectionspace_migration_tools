# frozen_string_literal: true

require 'base64'
require 'dry/monads'

module CollectionspaceMigrationTools
  module Xml
    # Base 64 hashed filenames for payloads to be transferred via S3
    class FileNamer
      include Dry::Monads[:result]
      
      # @param svc_path [String]
      def initialize(svc_path:)
        @svc_path = svc_path
        @separator = CMT.config.client.s3_delimiter
      end

      # @param response [CollectionSpace::Mapper::Response]
      def call(response, action)
        id = response.identifier
        result = Base64.urlsafe_encode64([svc_path, id, action].join(separator))
      rescue
        Failure(CMT::Failure.new(context: "#{self.class.name}.#{__callee__}", message: err))
      else
        Success(result)
      end

      def to_monad
        Success(self)
      end
      
      private
      
      attr_reader :svc_path, :separator
    end
  end
end

