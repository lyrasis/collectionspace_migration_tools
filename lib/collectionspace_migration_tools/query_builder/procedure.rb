# frozen_string_literal: true

require 'collectionspace/client'

module CollectionspaceMigrationTools
  module QueryBuilder
    class Procedure

      def self.call(rectype)
        self.new(rectype).call
      end
      
      def initialize(rectype)
        @name = rectype if CMT::RecordTypes.procedures.values.any?(rectype)
        return if name
        
        if CMT::RecordTypes.procedures.keys.any?(rectype)
          @name = CMT::RecordTypes.procedures[rectype]
        end
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
