# frozen_string_literal: true

require 'collectionspace/client'

module CollectionspaceMigrationTools
  module QueryBuilder
    class Procedure

      class << self
        def call(rectype)
          self.new(rectype).call
        end

        def duplicates(rectype)
          self.new(rectype).duplicates
        end
      end
      
      def initialize(rectype)
        @name = rectype if CMT::RecordTypes.procedures.any?(rectype)
        return if name
        
        raise(CMT::QB::UnknownTypeError, "Unknown record type: #{rectype}")
      end

      def call
          <<~SQL
            select '#{name}' as type, oap.#{field} as id, cc.refname, h.name as csid
            from #{table} oap
            inner join misc on oap.id = misc.id and misc.lifecyclestate != 'deleted'
            inner join hierarchy h on oap.id = h.id
            inner join collectionspace_core cc on oap.id = cc.id
          SQL
      end

      def duplicates
          <<~SQL
            select oap.#{field} from #{table} oap
            left join misc on oap.#{field} = misc.id
            where misc.lifecyclestate != 'deleted'
            group by oap.#{field}
            having count(oap.#{field})>1
          SQL
      end

      private

      attr_reader :name

      def field
        service_config[:identifier].downcase
      end
      
      # returns Hash from CollectionSpace::Service
      def service_config
        @service_config ||= CollectionSpace::Service.get(type: name)
      end

      def table
        "#{service_config[:ns_prefix]}_common"
      end
    end
  end
end
