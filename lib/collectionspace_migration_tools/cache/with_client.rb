# frozen_string_literal: true

module CollectionspaceMigrationTools
  module Cache
    # value object to bundle CollectionSpace::RefCache with CollectionSpace::Client
    class WithClient
      attr_reader :client, :cache

      def initialize(client, cache)
        @client = client
        @cache = cache
      end
    end
  end
end
