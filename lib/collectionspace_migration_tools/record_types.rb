# frozen_string_literal: true

require 'dry/monads'

module CollectionspaceMigrationTools
  module RecordTypes
    extend Dry::Monads[:result]
    
    module_function

    def authorities
      mappable.select{ |rectype| rectype['-'] }
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

    def valid_mappable?(rectype)
      return Success(rectype) if mappable.any?(rectype)
      
      Failure("Invalid rectype: #{rectype}. Do `thor rectypes:map` to see allowed values")
    end
  end
end
