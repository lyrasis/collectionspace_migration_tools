# frozen_string_literal: true

require 'dry/monads'

module CollectionspaceMigrationTools
  module RecordTypes
    extend Dry::Monads[:result]
    
    module_function

    def alt_auth_rectype_form(rectype)
      splitdata = rectype.split('-')
      type = splitdata.shift
      subtype = splitdata.join('-')

      if service_path_to_mappable_type_mapping.key?(type)
        newtype = service_path_to_mappable_type_mapping[type]
      else
        newtype = type
      end

      if authority_subtype_machine_to_human_label_mapping.key?(subtype)
        newsubtype = authority_subtype_machine_to_human_label_mapping[subtype]
      else
        newsubtype = subtype
      end

      result = [newtype, newsubtype].join('-')
      mappable.any?(result) ? Success(result) : Failure("Cannot derive valid rectype from #{rectype}")
    end
    
    def authorities
      mappable.select{ |rectype| rectype['-'] }
    end

    def authority_subtype_machine_to_human_label_mapping
      @authority_subtype_machine_to_human_label_mapping ||= get_authority_subtype_machine_to_human_label_mapping
    end
    
    def get_authority_subtype_machine_to_human_label_mapping
      # since each authority vocabulary record mapper lists all vocabs for that authority,
      #   we just take one per authority
      authorities.map{ |rectype| [rectype.split('-').first, rectype]}
        .to_h
        .values
        .map{ |rectype| CMT::Parse::RecordMapper.call(rectype).value!.vocabs }
        .inject({}, :merge)
    end
    
    def get_service_path_to_mappable_type_mapping
      mappable.map{ |rectype| CMT::Parse::RecordMapper.call(rectype).value!.service_path_to_mappable }
        .inject({}, :merge)
    end
    
    def mappable
      @mappable ||= Dir.new(CMT.config.client.mapper_dir)
        .children
        .map{ |fn| fn.delete_prefix("#{CMT.config.client.profile}_#{CMT.config.client.profile_version}_") }
        .map{ |fn| fn.delete_suffix(".json") }
        .sort
    end

    def object
      'collectionobject'
    end

    def relations
      %w[authorityhierarchy nonhierarchicalrelationship objecthierarchy].select{ |name| mappable.any?(name) }
    end
    
    def procedures
      mappable.reject{ |name| name['-'] || name == object }
        .reject{ |name| relations.any?(name) }
    end

    def service_path_to_mappable_type_mapping
      @service_path_to_mappable_type_mapping ||= get_service_path_to_mappable_type_mapping
    end

    def to_obj(rectype)
      return Success(CMT::Entity::Vocabulary.new) if rectype == 'vocabulary'
      return Success(CMT::Entity::Collectionobject.new) if rectype == 'collectionobject'
      return Success(CMT::Entity::Relation.new(rectype)) if relations.any?(rectype)
      return Success(CMT::Entity::Procedure.new(rectype)) if procedures.any?(rectype)
      return Success(CMT::Entity::Authority.from_str(rectype)) if authorities.any?(rectype)

      alt_auth_rectype_form(rectype).bind do |alt_form|
        return Success(CMT::Entity::Authority.from_str(alt_form)) if authorities.any?(alt_form)
      end

      Failure("#{rectype} cannot be converted to a CMT CS Entity object")
    end

    def valid_mappable?(rectype)
      return Success(rectype) if mappable.any?(rectype)
      
      Failure("Invalid rectype: #{rectype}. Do `thor rectypes:map` to see allowed values")
    end
  end
end
