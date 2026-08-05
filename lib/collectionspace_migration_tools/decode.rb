# frozen_string_literal: true

require "base64"

module CollectionspaceMigrationTools
  module Decode
    ::CMT::Decode = CollectionspaceMigrationTools::Decode
    extend Dry::Monads[:result, :do]

    module_function

    def key(key)
      result = Base64.urlsafe_decode64(key)

      Success(result)
    rescue => err
      Failure(err.message)
    end

    def segments(key)
      delim = CMT.config.client.s3_delimiter
      decoded = yield key(key)

      Success(decoded.split(delim))
    end

    def to_h(key)
      parts = yield segments(key)

      Success({
        key: key,
        batch: parts[0],
        path: parts[1],
        id: parts[2],
        action: parts[3]
      })
    end
  end
end
