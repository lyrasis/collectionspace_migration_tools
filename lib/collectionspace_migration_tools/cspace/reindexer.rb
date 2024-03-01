# frozen_string_literal: true

module CollectionspaceMigrationTools
  module Cspace
    # Posts to /cspace-services/index/elasticsearch, triggering fulltext
    # reindexing of the CollectionSpace instance
    class Reindexer
      include Dry::Monads[:result]
      include Dry::Monads::Do.for(:call)

      class << self
        def call
          new.call
        end
      end

      def call
        client = yield CMT::Client.call
        _result = yield post_command(client)

        Success()
      end

      private

      def post_command(client)
        result = client.send(:request, "POST", "/index/elasticsearch")
        return Success() if result.status_code == 200

        Failure(result.status_code)
      end
    end
  end
end
