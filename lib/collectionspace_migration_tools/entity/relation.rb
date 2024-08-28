# frozen_string_literal: true

module CollectionspaceMigrationTools
  module Entity
    # @note There is no `duplicate` method for relation because I have
    #   been unable to populate an instance with any duplicate
    #   relations to test such a query. The API seems to be pretty
    #   thorough at returning 409 error instead of creating duplicate
    #   relations.
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
          select rc.subjectcsid, ccsub.uri as subjecturi,
            rc.relationshiptype,
            rc.objectcsid, ccobj.uri as objecturi,
            h.name as csid
          from relations_common rc
          inner join misc on rc.id = misc.id
            and misc.lifecyclestate != 'deleted'
          inner join hierarchy h on rc.id = h.id
          inner join hierarchy hsub on rc.subjectcsid = hsub.name
          inner join hierarchy hobj on rc.objectcsid = hobj.name
          inner join collectionspace_core ccsub on ccsub.id = hsub.id
          inner join collectionspace_core ccobj on ccobj.id = hobj.id
          #{constraint}
        SQL

        Success(query)
      end

      def constraint
        case name
        when "authorityhierarchy"
          "where rc.relationshiptype = 'hasBroader' "\
          "and hsub.primarytype not like 'CollectionObject%'"
        when "nonhierarchicalrelationship"
          "where rc.relationshiptype = 'affects' "
        when "objecthierarchy"
          "where rc.relationshiptype = 'hasBroader' "\
            "and hsub.primarytype like 'CollectionObject%'"
        end
      end

      def name_type_lookup
        {
          "authorityhierarchy" => :hier,
          "nonhierarchicalrelationship" => :nhr,
          "objecthierarchy" => :hier
        }
      end

      def rectype_mixin
        "Relations"
      end

      def set_name(rectype)
        if CMT::RecordTypes.relations.any?(rectype)
          @name = rectype
          @status = Success(self)
        else
          @status = Failure("#{rectype} is not a valid relation rectype. Do "\
                            "`thor rt:rels` for list of allowed rectypes")
        end
      end

      def set_type
        return if status.failure?

        @type = name_type_lookup[name]
      end
    end
  end
end
