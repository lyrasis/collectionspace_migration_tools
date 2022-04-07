# frozen_string_literal: true

require 'collectionspace/client'

module CollectionspaceMigrationTools
  module QueryBuilder
    class Object

      def self.call
        <<~SQL
          select obj.objectnumber as id, cc.refname, h.name as csid
          from collectionobjects_common obj
          inner join misc on obj.id = misc.id and misc.lifecyclestate != 'deleted'
          inner join hierarchy h on obj.id = h.id
          inner join collectionspace_core cc on obj.id = cc.id
        SQL
      end

      def self.duplicates
        <<~SQL
          select cc.objectnumber from collectionobjects_common cc
          left join misc on cc.id = misc.id
          where misc.lifecyclestate != 'deleted'
          group by cc.objectnumber
          having count(cc.objectnumber)>1
        SQL
      end
    end
  end
end
