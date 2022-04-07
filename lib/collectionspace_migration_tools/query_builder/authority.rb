# frozen_string_literal: true

require 'collectionspace/client'
require 'dry/monads'

module CollectionspaceMigrationTools
  module QueryBuilder
    class Authority
      include Dry::Monads[:result]

      class VocabLookupError < CMT::Error; end
      class InvalidVocabError < CMT::Error; end

      class << self
        def call(rectype, vocab = nil)
          self.new(rectype, vocab).call
        end

        def duplicates(rectype, vocab)
          self.new(rectype, vocab).duplicates
        end
      end
      
      attr_reader :name, :vocab, :vocabs

      def initialize(rectype, vocab = nil)
        @name = rectype
        @vocab = vocab
        raise(CMT::QB::UnknownTypeError, "Unknown record type: #{rectype}") unless valid?

        if vocab
          set_vocabs
          raise(CMT::QB::Authority::VocabLookupError, "Cannot get vocabs for: #{rectype}") unless vocabs
          return unless vocab

          unless vocabs.any?(vocab)
            raise(CMT::QB::Authority::InvalidVocabError, "#{vocab} does not exist. Use of the following: #{vocabs.join(', ')}")
          end
        end
      end

      def call
        scope = vocab ? "where acv.shortidentifier = '#{vocab}'" : ''
          <<~SQL
            with auth_vocab_csid as (
            select acv.id, h.name as csid, acv.shortidentifier from #{vocab_table} acv
            inner join hierarchy h on acv.id = h.id
            #{scope}
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

      def duplicates
        <<~SQL
            with auth_vocab_csid as (
            select acv.id, h.name as csid, acv.shortidentifier from #{vocab_table} acv
            inner join hierarchy h on acv.id = h.id
            where acv.shortidentifier = '#{vocab}'
            ),
            terms as (
            select h.parentid as id, tg.termdisplayname from hierarchy h
            inner join #{term_table} ac on ac.id = h.parentid and h.name like '%TermGroupList' and pos = 0
            inner join #{term_group_table} tg on h.id = tg.id
            )
            
            select t.termdisplayname from #{term_table} ac
            inner join misc on ac.id = misc.id and misc.lifecyclestate != 'deleted'
            inner join auth_vocab_csid acv on ac.inauthority = acv.csid
            inner join terms t on ac.id = t.id
            inner join hierarchy h on ac.id = h.id
            group by t.termdisplayname
            having count(t.termdisplayname)>1
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

      def set_vocabs
        puts "Verifying authority vocabulary..."
        do_vocab_query.bind{ |rows| @vocabs = rows.values.flatten }
      end

      def do_vocab_query
        query = "select shortidentifier from #{vocab_table}"
        CMT::Database::ExecuteQuery.call(query)
      end
      
    end
  end
end
