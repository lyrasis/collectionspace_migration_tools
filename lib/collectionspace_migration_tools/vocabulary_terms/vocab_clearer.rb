# frozen_string_literal: true

require "collectionspace/mapper"
require "dry/monads"
require "dry/monads/do"

module CollectionspaceMigrationTools
  module VocabularyTerms
    # Soft delete all terms in the given vocabulary.
    #
    # We soft delete them because this blocks their automatic readdition
    #   by the application on upgrade.
    class VocabClearer
      include Dry::Monads[:result]
      include Dry::Monads::Do.for(:call)

      class << self
        def call(...)
          new(...).call
        end
      end

      # @param vocab [String] display or machine name of vocabulary
      # @param client [CollectionSpace::Client, nil] calls `CMT.client` if
      #   not client param given
      def initialize(vocabname:, client: nil)
        @vocabname = vocabname
        @client = client || CMT.client
      end

      def call
        handler = yield CMT::Build::VocabHandler.call(client)
        vocab = yield CollectionSpace::Mapper::Vocabularies.new(client)
          .by_name(vocabname)

        _deleter = yield delete_terms_from(vocab, handler)

        client.config.include_deleted = false

        Success()
      end

      private

      attr_reader :vocabname, :client

      def delete_terms_from(vocab, handler)
        path = "#{vocab["uri"]}/items"
        client.all(path)
          .each { |term| delete_term(term, handler) }

        Success()
      rescue => err
        Failure(err)
      end

      def delete_term(term, handler)
        term["uri"]
        termstring = term["displayName"]

        case term["workflowState"]
        when "project"
          r = handler.delete_term(vocab: vocabname, term: termstring)
          r.either(
            ->(_success) { puts "Deleted `#{termstring}`" },
            ->(failure) do
              puts "Could not delete `#{termstring}`: #{failure}"
            end
          )
        when "deleted"
          puts "Nothing to do: `#{termstring}` is already soft deleted"
        end
      rescue => err
        puts "ERROR deleting `#{termstring}`: #{err.message}"
      end
    end
  end
end
