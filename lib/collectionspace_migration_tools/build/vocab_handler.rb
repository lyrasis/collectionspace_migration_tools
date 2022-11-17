# frozen_string_literal: true

require 'collectionspace/mapper'
require 'dry/monads'

module CollectionspaceMigrationTools
  module Build
  # Returns CollectionSpace::Mapper::VocabularyTerms::Handler
    class VocabHandler
      include Dry::Monads[:result]

      class << self
        def call
          self.new.call
        end
      end

      def initialize
      end

      def call
        result = CollectionSpace::Mapper::VocabularyTerms::Handler.new(
          client: CMT.client
        )
      rescue CollectionSpace::Mapper::NoClientServiceError => err
        msg = "collectionspace-client does not have a service configured for #{err.message}"
        Failure(CMT::Failure.new(context: "#{self.class.name}.#{__callee__}", message: msg))
      rescue StandardError => err
        Failure(CMT::Failure.new(context: "#{self.class.name}.#{__callee__}", message: err))
      else
        Success(result)
      end
    end
  end
end
