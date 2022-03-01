# frozen_string_literal: true

require 'collectionspace/client'

module CollectionspaceMigrationTools
  module QueryBuilder
    class Authority

      def self.call(rectype)
        self.new(rectype).call
      end
      
      attr_reader :name

      def initialize(rectype)
        @name = rectype
        raise(CMT::QB::UnknownTypeError, "Unknown record type: #{rectype}") unless valid?
      end

      def call
          <<~SQL
            with auth_vocab_csid as (
            select acv.id, h.name as csid, acv.shortidentifier from #{vocab_table} acv
            inner join hierarchy h on acv.id = h.id
            ),
            terms as (
            select h.parentid as id, tg.termdisplayname from hierarchy h
            inner join #{term_table} ac on ac.id = h.parentid and h.name like '%TermGroupList' and pos = 0
            inner join #{term_group_table} tg on h.id = tg.id
            )
            
            select '#{service_type}' as type, acv.shortidentifier as subtype, t.termdisplayname as term, ac.refname, h.name as csid
            from #{term_table} ac
            inner join misc on ac.id = misc.id and misc.lifecyclestate != 'deleted'
            inner join auth_vocab_csid acv on ac.inauthority = acv.csid
            inner join terms t on ac.id = t.id
            inner join hierarchy h on ac.id = h.id
          SQL
      end

      private
      
      # returns Hash from CollectionSpace::Service
      def service_config
        @service_config ||= CollectionSpace::Service.get(type: service_type)
      end

      # returns `type` value to be used in cache hash key
      def service_type
        return @service_type if instance_variable_defined?(:@service_type)

        set_service_type
      end

      def term_table
        "#{service_config[:ns_prefix]}_common"
      end

      def term_group_table
        service_config[:term].sub(/GroupList.*/, 'group').downcase
      end
      
      def vocab_table
        "#{service_type}_common"
      end

      def set_service_type
        case name
        when 'organization'
          @service_type = 'orgauthorities'
        when 'taxon'
          @service_type = 'taxonomyauthority'
        else
          @service_type = "#{name}authorities"
        end
        @service_type
      end

      def valid?
        CMT::RecordTypes.authority.any?(name)
      end
    end
  end
end
