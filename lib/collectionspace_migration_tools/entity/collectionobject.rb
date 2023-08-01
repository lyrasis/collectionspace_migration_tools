# frozen_string_literal: true

module CollectionspaceMigrationTools
  module Entity
    class Collectionobject
      include CMT::Cache::Populatable
      include CMT::Duplicate::Checkable
      include CMT::Entity::DeleteAllable

      def status
        to_monad
      end

      def to_monad
        Success()
      end

      def to_s
        'collectionobject'
      end

      def name
        to_s
      end

      private

      def cacheable_data_query
        query = <<~SQL
          select obj.objectnumber as id, cc.refname, h.name as csid
          from collectionobjects_common obj
          inner join misc on obj.id = misc.id and misc.lifecyclestate != 'deleted'
          inner join hierarchy h on obj.id = h.id
          inner join collectionspace_core cc on obj.id = cc.id
          SQL

        Success(query)
      end

      def duplicates_query
        query = <<~SQL
          select cc.objectnumber from collectionobjects_common cc
          left join misc on cc.id = misc.id
          where misc.lifecyclestate != 'deleted'
          group by cc.objectnumber
          having count(cc.objectnumber)>1
          SQL

        Success(query)
      end

      def all_csids_query
        query = <<~SQL
        select h.name as csid, '#{to_s}' as rectype
          from collectionobjects_common obj
          inner join misc on obj.id = misc.id
            and misc.lifecyclestate != 'deleted'
          inner join hierarchy h on obj.id = h.id
          SQL

        Success(query)
      end

      def rectype_mixin
        'Objects'
      end
    end
  end
end
