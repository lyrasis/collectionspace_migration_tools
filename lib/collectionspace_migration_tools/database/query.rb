# frozen_string_literal: true

module CollectionspaceMigrationTools
  module Database
    module Query
      module_function

      def blobs_on_media
        %{ with blobs as (
          select hier.name as blobcsid, bc.name as filename, bc.mimetype
          from blobs_common bc
          inner join misc ON misc.id = bc.id
            AND misc.lifecyclestate != 'deleted'
          inner join hierarchy hier on hier.id = bc.id
        )
        select med.identificationnumber, hier.name as mhcsid, blobs.*
        from media_common med
        inner join hierarchy hier on med.id = hier.id
        inner join misc ON misc.id = med.id AND misc.lifecyclestate != 'deleted'
          AND misc.lifecyclestate != 'deleted'
        left outer join blobs on med.blobcsid = blobs.blobcsid }
      end

      def refnames
        %( SELECT CC.REFNAME FROM PUBLIC.COLLECTIONSPACE_CORE CC
           INNER JOIN MISC ON CC.ID = MISC.ID
             AND MISC.LIFECYCLESTATE != 'deleted'
           WHERE CC.URI not like '/contacts%'
           AND CC.URI not like '/relations%'
           AND CC.URI not like '/blobs%'
           AND CC.URI not like '/reports%'
           AND CC.URI not like '/batch%' )
      end

      def test
        %( #{refnames}
           LIMIT 25 )
      end
    end
  end
end
