# frozen_string_literal: true

require 'collectionspace/client'

module CollectionspaceMigrationTools
  module QueryBuilder
    # @note There is no `duplicate` method for relation because I have been unable to populate an instance
    #   with any duplicate relations to test such a query. The API seems to be pretty thorough at returning
    #   409 error instead of creating duplicate relations.
    class Relation
      def self.call(rectype)
        self.new(rectype).call
      end
      
      def initialize(rectype)
        @name = rectype if rectypes.any?(rectype)
        return if name

        raise(CMT::QB::UnknownTypeError, "Unknown record type: #{rectype}")
      end

      def call
        <<~SQL
          select rc.subjectcsid, rc.relationshiptype, rc.objectcsid, h.name as csid from relations_common rc
          inner join misc on rc.id = misc.id and misc.lifecyclestate != 'deleted'
          inner join hierarchy h on rc.id = h.id
          inner join collectionspace_core cc on rc.id = cc.id
          #{predicate(name)}
        SQL
      end

      private

      attr_reader :name

      def predicate(name)
        lookup = {
          'hier' => "where rc.relationshiptype = 'hasBroader'",
          'nhr' => "where rc.relationshiptype = 'affects'",
          'all' => ''
        }

        lookup[name]
      end
      
      def rectypes
        %w[hier nhr all]
      end
    end
  end
end
