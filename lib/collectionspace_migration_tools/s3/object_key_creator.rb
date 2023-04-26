# frozen_string_literal: true

require 'base64'
require 'dry/monads'
require 'erb'

module CollectionspaceMigrationTools
  module S3
    ObjKey = Struct.new(:value, :warnings, keyword_init: true)

    # Base 64 hashed filenames for payloads to be transferred via S3
    class ObjectKeyCreator
      include Dry::Monads[:result]
      include ERB::Util

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
        warnings = []
        final_path = get_final_path(response, base_path, warnings)
        result = Base64.urlsafe_encode64(
          [batch, final_path, id, action].join(separator)
        )
      rescue
        Failure(
          CMT::Failure.new(
            context: "#{self.class.name}.#{__callee__}",
            message: err
          )
        )
      else
        Success(CMT::S3::ObjKey.new(value: result, warnings: warnings))
      end

      def to_monad
        Success(self)
      end

      private

      attr_reader :svc_path, :batch, :separator

      def get_final_path(response, base_path, warnings)
        return base_path unless svc_path == '/media'

        media_uri = response.orig_data['mediafileuri']
        return base_path if media_uri.blank?

        media_path(media_uri, base_path, warnings)
      end

      def media_path(media_uri, base_path, warnings)
        blob_uri = prepare_media_uri(media_uri, warnings)
        if blob_uri
          "#{base_path}?blobUri=#{blob_uri}"
        else
          base_path
        end
      end

      def prepare_media_uri(media_uri, warnings)
        space_escaped = media_uri.gsub(" ", "%20")
        all_escaped = ERB::Util.url_encode(space_escaped)
        result = URI(all_escaped)
      rescue URI::Error
        warnings << 'media_uri cannot be encoded as valid ingest URI. File '\
          'ingest may not work as expected'
        media_uri
      else
        result.to_s
      end
    end
  end
end
