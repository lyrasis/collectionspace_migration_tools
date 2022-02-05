# frozen_string_literal: true

module CollectionspaceMigrationTools
  module Database
    module Query

      module_function

      def refnames
        %{ SELECT CC.REFNAME FROM PUBLIC.COLLECTIONSPACE_CORE CC
           INNER JOIN MISC ON CC.ID = MISC.ID AND MISC.LIFECYCLESTATE != 'deleted'
           WHERE CC.URI not like '/contacts%'
           AND CC.URI not like '/relations%'
           AND CC.URI not like '/blobs%'
           AND CC.URI not like '/reports%'
           AND CC.URI not like '/batch%' }
      end

      def test
        %{ #{refnames}
           LIMIT 25 }
      end
    end
  end
end
