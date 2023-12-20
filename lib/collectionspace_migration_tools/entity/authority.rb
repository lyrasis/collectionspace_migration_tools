# frozen_string_literal: true

module CollectionspaceMigrationTools
  module Entity
    class Authority
      include CMT::Cache::Populatable
      include CMT::Duplicate::Checkable
      include CMT::Entity::DeleteAllable
      include CMT::Mappable
      include Dry::Monads[:result]

      class << self
        def from_str(str)
          arr = str["/"] ? str.split("/") : str.split("-")
          new(type: arr.shift, subtype: arr.join("-"))
        end
      end

      attr_reader :type, :subtype, :name, :status

      def initialize(type:, subtype:)
        @type = type
        @subtype = subtype
        @name = "#{type}-#{subtype}"
        get_mapper
      end

      def to_s
        "<##{self.class}:#{object_id.to_s(8)} #{name}>"
      end
      alias_method :inspect, :to_s

      private

      attr_reader :mapper

      def cacheable_data_query
        return status if status.failure?

        query = <<~SQL
          with auth_vocab_csid as (
            select acv.id, h.name as csid, acv.shortidentifier
              from #{db_vocab_table} acv
            inner join hierarchy h on acv.id = h.id
            where acv.shortidentifier = '#{mapper.subtype}'
          ),
          terms as (
            select h.parentid as id, tg.termdisplayname from hierarchy h
            inner join #{mapper.base_namespace} ac
              on ac.id = h.parentid
                and h.name like '%TermGroupList'
                and pos = 0
            inner join #{mapper.db_term_group_table_name} tg
              on h.id = tg.id
          )

          select '#{service_path}' as type, acv.shortidentifier as subtype,
            t.termdisplayname as term, ac.refname, h.name as csid
            from #{db_term_table} ac
            inner join misc on ac.id = misc.id
              and misc.lifecyclestate != 'deleted'
            inner join auth_vocab_csid acv on ac.inauthority = acv.csid
            inner join terms t on ac.id = t.id
            inner join hierarchy h on ac.id = h.id
        SQL

        Success(query)
      end

      # i.e. personauthorities, orgauthorities
      def cacheable_type
        return status if status.failure?

        mapper.type
      end

      def db_term_table
        return status if status.failure?

        "#{mapper.document_name}_common"
      end

      def duplicates_query
        return status if status.failure?

        query = <<~SQL
          with auth_vocab_csid as (
          select acv.id, h.name as csid, acv.shortidentifier from #{db_vocab_table} acv
          inner join hierarchy h on acv.id = h.id
          where acv.shortidentifier = '#{mapper.subtype}'
          ),
          terms as (
          select h.parentid as id, tg.termdisplayname from hierarchy h
          inner join #{db_term_table} ac on ac.id = h.parentid and h.name like '%TermGroupList' and pos = 0
          inner join #{mapper.db_term_group_table_name} tg on h.id = tg.id
          )

          select t.termdisplayname from #{db_term_table} ac
          inner join misc on ac.id = misc.id and misc.lifecyclestate != 'deleted'
          inner join auth_vocab_csid acv on ac.inauthority = acv.csid
          inner join terms t on ac.id = t.id
          inner join hierarchy h on ac.id = h.id
          group by t.termdisplayname
          having count(t.termdisplayname)>1
        SQL

        Success(query)
      end

      def db_vocab_table
        return status if status.failure?

        "#{cacheable_type}_common"
      end

      def rectype_mixin
        "AuthTerms"
      end

      def service_path
        return status if status.failure?

        mapper.service_path
      end

      def all_csids_query
        return status if status.failure?

        query = <<~SQL
          with auth_vocab_csid as (
            select acv.id, h.name as csid, acv.shortidentifier
              from #{db_vocab_table} acv
            inner join hierarchy h on acv.id = h.id
            where acv.shortidentifier = '#{mapper.subtype}'
          )
          select '#{name}' as rectype, h.name as csid
            from #{db_term_table} ac
            inner join misc on ac.id = misc.id
              and misc.lifecyclestate != 'deleted'
            inner join auth_vocab_csid acv on ac.inauthority = acv.csid
            inner join hierarchy h on ac.id = h.id
        SQL

        Success(query)
      end
    end
  end
end
