# frozen_string_literal: true

require 'base64'
require 'dry/monads'

module CollectionspaceMigrationTools
  module S3
    # Base 64 hashed filenames for payloads to be transferred via S3
    class ObjectKeyCreator
      include Dry::Monads[:result]
      
      # @param svc_path [String]
      def initialize(svc_path:, batch: nil)
        @svc_path = svc_path
        @batch = batch.nil? ? 'na' : batch
        @separator = CMT.config.client.s3_delimiter
      end

      # @param response [CollectionSpace::Mapper::Response]
      def call(response, action)
        id = response.identifier
        base_path = action == 'CREATE' ? svc_path : "#{svc_path}/#{response.csid}"
        final_path = svc_path == '/media' ? media_path(response, base_path) : base_path
        result = Base64.urlsafe_encode64([batch, final_path, id, action].join(separator))
      rescue
        Failure(CMT::Failure.new(context: "#{self.class.name}.#{__callee__}", message: err))
      else
        Success(result)
      end

      def to_monad
        Success(self)
      end
      
      private
      
      attr_reader :svc_path, :batch, :separator

      def media_path(response, base_path)
        media_uri = response.orig_data['mediafileuri']
        return base_path if media_uri.blank?

        "#{base_path}?blobUri=#{URI(media_uri)}"
      end
    end
  end
end

