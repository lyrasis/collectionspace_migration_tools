# frozen_string_literal: true

require "base64"
require "dry/monads"
require "dry/monads/do"

module CollectionspaceMigrationTools
  module Xml
    # Generates safe filename from a Base64 hash of the record identifier. We
    #   use a hashed value because:
    #   - record ids can contain characters not allowed in filenames
    #   - we don't want false duplicate IDs reported because we stripped some
    #     data from the IDs out or changed it
    class FileNamer
      include Dry::Monads[:result]
      include Dry::Monads::Do.for(:call)

      # @param svc_path [String]
      def initialize
      end

      # @param response [CollectionSpace::Mapper::Response]
      def call(response)
        id = yield(get_id(response))
        hashed = yield(encode(id))

        Success("#{hashed}.xml")
      end

      def to_monad
        Success(self)
      end

      private

      def encode(id)
        hashed = Base64.urlsafe_encode64(id)
      rescue => err
        Failure(CMT::Failure.new(
          context: "#{self.class.name}.#{__callee__}", message: err
        ))
      else
        Success(hashed)
      end

      def get_id(response)
        id = response.identifier
        if id.blank?
          return Failure(CMT::Failure.new(
            context: "#{self.class.name}.#{__callee__}",
            message: "no id found for record"
          ))
        end

        Success(id)
      end
    end
  end
end
