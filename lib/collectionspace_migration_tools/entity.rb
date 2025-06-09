# frozen_string_literal: true

module CollectionspaceMigrationTools
  module Entity
    module_function

    def authorities
      CMT::RecordTypes.authorities.map do |str|
        CMT::Entity::Authority.from_str(str)
      end
    end

    def procedures
      CMT::RecordTypes.procedures.map do |str|
        CMT::Entity::Procedure.new(str)
      end
    end

    def relations
      CMT::RecordTypes.relations.map { |str| CMT::Entity::Relation.new(str) }
    end
  end
end
