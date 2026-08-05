# frozen_string_literal: true

require "collectionspace/mapper"

module CollectionspaceMigrationTools
  module Build
    # Returns CollectionSpace::Mapper::VocabularyTerms::Handler
    class VocabHandler
      include Dry::Monads[:result]

      class << self
        def call(...)
          new.call(...)
        end
      end

      def call(client = nil)
        use_client = client || CMT::Client.call(include_deleted: true).value!
        result = CollectionSpace::Mapper::VocabularyTerms::Handler.new(
          client: use_client
        )

        Success(result)
      rescue CollectionSpace::Mapper::NoClientServiceError => err
        Failure("collectionspace-client does not have a service configured "\
          "for #{err.message}")
      rescue => err
        Failure(err.message)
      end
    end
  end
end
