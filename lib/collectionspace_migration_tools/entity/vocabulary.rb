# frozen_string_literal: true

module CollectionspaceMigrationTools
  module Entity
    # @note There is no `duplicate` method for vocabulary terms at this point
    #   because:
    #   - we are not batch uploading them yet, so there is no opportunity for
    #   duplicates to be introduced by the S3/Lambda ingest process
    #   - generally vocabularies are small enough we can take care of any
    #   duplicates manually
    class Vocabulary
      include CMT::Cache::Populatable

      class << self
        def services_api_path = "vocabularies"
      end

      def initialize
      end

      def status
        to_monad
      end

      def to_monad
        Success()
      end

      def name
        "vocabularies"
      end

      private

      def cacheable_data_query
        query = <<~SQL
          with vocab_csids as (
          select vc.id, h.name as csid, vc.shortidentifier from vocabularies_common vc
          inner join hierarchy h on vc.id = h.id
          )

          select vc.shortidentifier as vocab, vic.displayname as term, vic.refname, h.name as csid
          from vocabularyitems_common vic
          inner join misc on vic.id = misc.id and misc.lifecyclestate != 'deleted'
          inner join vocab_csids vc on vic.inauthority = vc.csid
          inner join hierarchy h on vic.id = h.id
        SQL

        Success(query)
      end

      def rectype_mixin
        "VocabTerms"
      end
    end
  end
end
