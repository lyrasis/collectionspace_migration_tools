# frozen_string_literal: true

# @todo delete
require 'collectionspace/client'

module CollectionspaceMigrationTools
  module QueryBuilder
    # @note There is no `duplicate` method for vocabulary terms at this point because:
    #   - we are not batch uploading them yet, so there is no opportunity for duplicates to be
    #     introduced by the S3/Lambda ingest process
    #   - generally vocabularies are small enough we can take care of any duplicates manually
    class Vocabulary
      def self.call
        <<~SQL
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
      end
    end
  end
end
