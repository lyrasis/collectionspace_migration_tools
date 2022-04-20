# frozen_string_literal: true

module CollectionspaceMigrationTools
  module Entity
    class Procedure
      include CMT::Cache::Populatable
      include CMT::Duplicate::Checkable
      include CMT::Mappable

      attr_reader :name, :status
      
      def initialize(name)
        @name = name
        get_mapper
      end
      
      private

      attr_reader :mapper
      
      def cacheable_data_query
        return status if status.failure?
        
        query =    <<~SQL
            select '#{name}' as type, oap.#{mapper.id_field} as id, cc.refname, h.name as csid
            from #{mapper.base_namespace} oap
            inner join misc on oap.id = misc.id and misc.lifecyclestate != 'deleted'
            inner join hierarchy h on oap.id = h.id
            inner join collectionspace_core cc on oap.id = cc.id
          SQL

        Success(query)
      end

      def duplicates_query
        return status if status.failure?

        field = mapper.id_field
        
        query = <<~SQL
            select oap.#{field} from #{mapper.base_namespace} oap
            left join misc on oap.#{field} = misc.id
            where misc.lifecyclestate != 'deleted'
            group by oap.#{field}
            having count(oap.#{field})>1
        SQL

        Success(query)
      end

      def rectype_mixin
        'Procedures'
      end
    end
  end
end
