# frozen_string_literal: true

require 'dry/monads'

module CollectionspaceMigrationTools
  module RecordTypes
    extend Dry::Monads[:result]
    
    module_function

    def authorities
      mappable.select{ |rectype| rectype['-'] }
    end

    def authority_subtype_machine_to_human_label_mapping
      # since each authority vocabulary record mapper lists all vocabs for that authority,
      #   we just take one per authority
      authorities.map{ |rectype| [rectype.split('-').first, rectype]}
        .to_h
        .values
        .map{ |rectype| CMT::Parse::RecordMapper.call(rectype).value!.vocabs }
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
      mappable.map{ |rectype| CMT::Parse::RecordMapper.call(rectype).value!.service_path_to_mappable }
        .inject({}, :merge)
    end

    def valid_mappable?(rectype)
      return Success(rectype) if mappable.any?(rectype)
      
      Failure("Invalid rectype: #{rectype}. Do `thor rectypes:map` to see allowed values")
    end
  end
end
