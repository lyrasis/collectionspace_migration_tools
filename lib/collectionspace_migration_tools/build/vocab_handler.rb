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
        use_client = client || CMT.client
        use_client.config.include_deleted = true
        result = CollectionSpace::Mapper::VocabularyTerms::Handler.new(
          client: use_client
        )
      rescue CollectionSpace::Mapper::NoClientServiceError => err
        msg = "collectionspace-client does not have a service configured "\
          "for #{err.message}"
        Failure(CMT::Failure.new(context: "#{self.class.name}.#{__callee__}",
          message: msg))
      rescue => err
        Failure(CMT::Failure.new(context: "#{self.class.name}.#{__callee__}",
          message: err))
      else
        Success(result)
      end
    end
  end
end
