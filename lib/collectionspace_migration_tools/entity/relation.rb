# frozen_string_literal: true

module CollectionspaceMigrationTools
  module Entity
    # @note There is no `duplicate` method for relation because I have
    #   been unable to populate an instance with any duplicate
    #   relations to test such a query. The API seems to be pretty
    #   thorough at returning 409 error instead of creating duplicate
    #   relations.
    # @note CollectionSpace itself handles deleting relationships between
    #   records when one of the records is deleted, so DeleteAllable is not
    #   mixed in here.
    class Relation
      include CMT::Cache::Populatable
      include CMT::Mappable

      attr_reader :status

      def initialize(rectype)
        @name = rectype
        check_name(rectype)
        return if status

        get_mapper
        set_type
      end

      def to_s
        name
      end

      def cacheable_data_query
        # rubocop:disable Layout/LineLength
        query = <<~SQL
          select rc.subjectcsid, rc.relationshiptype, rc.objectcsid, h.name as csid from relations_common rc
          inner join misc on rc.id = misc.id and misc.lifecyclestate != 'deleted'
          inner join hierarchy h on rc.id = h.id
          #{constraint}
          #{predicate}
        SQL
        # rubocop:enable Layout/LineLength

        Success(query)
      end

      private

      attr_reader :name, :mapper, :type

      def constraint
        name_constraint_lookup[name]
      end

      def name_constraint_lookup
        # rubocop:disable Layout/LineLength
        {
          "authorityhierarchy" =>
            "inner join hierarchy hh on rc.subjectcsid = hh.name and hh.primarytype not like 'CollectionObject%'",
          "nonhierarchicalrelationship" => "",
          "objecthierarchy" =>
            "inner join hierarchy hh on rc.subjectcsid = hh.name and hh.primarytype like 'CollectionObject%'"
        }
        # rubocop:enable Layout/LineLength
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

      def check_name(rectype)
        return unless CMT::RecordTypes.relations.none?(rectype)

        @status = Failure("#{rectype} is not a valid relation rectype. Do "\
                          "`thor rt:rels` for list of allowed rectypes")
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
