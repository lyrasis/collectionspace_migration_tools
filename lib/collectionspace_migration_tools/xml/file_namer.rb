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

        Success(hashed)
      rescue => err
        Failure(err.message)
      end

      def get_id(response)
        id = response.identifier
        return Failure("no id found for record") if id.blank?

        Success(id)
      end
    end
  end
end
