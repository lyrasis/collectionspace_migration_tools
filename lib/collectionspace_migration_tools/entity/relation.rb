# frozen_string_literal: true

module CollectionspaceMigrationTools
  module Entity
    # @note There is no `duplicate` method for relation because I have been unable to populate an instance
    #   with any duplicate relations to test such a query. The API seems to be pretty thorough at returning
    #   409 error instead of creating duplicate relations.
    class Relation
      include CMT::Cache::Populatable

      attr_reader :status

      def initialize(rectype)
        set_name(rectype)
        set_type
      end

      def to_monad
        status
      end

      def to_s
        name
      end

      private

      attr_reader :name, :type

      def cacheable_data_query
        query = <<~SQL
          select rc.subjectcsid, rc.relationshiptype, rc.objectcsid, h.name as csid from relations_common rc
          inner join misc on rc.id = misc.id and misc.lifecyclestate != 'deleted'
          inner join hierarchy h on rc.id = h.id
          #{constraint}
          #{predicate}
        SQL

        Success(query)
      end

      def constraint
        name_constraint_lookup[name]
      end

      def name_constraint_lookup
        {
          "authorityhierarchy" => "inner join hierarchy hh on rc.subjectcsid = hh.name and hh.primarytype not like 'CollectionObject%'",
          "nonhierarchicalrelationship" => "",
          "objecthierarchy" => "inner join hierarchy hh on rc.subjectcsid = hh.name and hh.primarytype like 'CollectionObject%'"
        }
      end

      def name_type_lookup
        {
          "authorityhierarchy" => :hier,
          "nonhierarchicalrelationship" => :nhr,
          "objecthierarchy" => :hier
        }
      end

      def predicate
        type_predicate_lookup[type]
      end

      def rectype_mixin
        "Relations"
      end

      def set_name(rectype)
        if CMT::RecordTypes.relations.any?(rectype)
          @name = rectype
          @status = Success(self)
        else
          @status = Failure("#{rectype} is not a valid relation rectype. Do `thor rt:rels` for list of allowed rectypes")
        end
      end

      def set_type
        return if status.failure?

        @type = name_type_lookup[name]
      end

      def type_predicate_lookup
        {
          hier: "where rc.relationshiptype = 'hasBroader'",
          nhr: "where rc.relationshiptype = 'affects'"
        }
      end
    end
  end
end
