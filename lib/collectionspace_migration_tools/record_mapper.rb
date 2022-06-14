# frozen_string_literal: true

require 'dry/monads'

module CollectionspaceMigrationTools
  class RecordMapper
    include Dry::Monads[:result]

    attr_reader :to_h

    def initialize(hash)
      @to_h = hash
      @config = to_h['config']
      @mappings = to_h['mappings']
    end

    def authority?
      service_type == 'authority'
    end

    def base_namespace
      config['ns_uri'].keys
        .select{ |ns| ns.end_with?('_common') && ( ns[type_label] || ns[service_path] ) }
        .first
    end

    def db_term_group_table_name
      term_group_list_key.delete_suffix('List').downcase
    end
    
    def document_name
      config['document_name']
    end
    
    def existence_check_method
      if object?
        :object_exists?
      elsif procedure?
        :procedure_exists?
      elsif authority?
        :auth_term_exists?
      elsif relation?
        :relation_exists?
      end
    end

    def name
      config['mapper_name']
    end

    def object?
      service_type == 'procedure'
    end

    def procedure?
      service_type == 'object'
    end

    def id_field
      config['identifier_field']
    end

    def mappable_to_service_path
      {config['recordtype'] => service_path}
    end
    
    def refname_columns
      mappings.select{ |mapping| requires_refname?(mapping) }
    end

    def relation?
      service_type == 'relation'
    end
    
    def type
      authority? ? config['authority_type'] : service_path
    end

    def type_subtype
      [type_label, subtype].compact.join('_')
    end

    def type_label
      config['recordtype']
    end

    def search_field
      config['search_field']
    end
    
    def subtype
      config['authority_subtype'] if authority?
    end

    def service_path
      config['service_path']
    end

    def service_path_to_mappable
      {service_path => config['recordtype']}
    end
    
    def service_type
      config['service_type']
    end

    def to_monad
      Success(self)
    end

    def to_s
      "<##{self.class}:#{self.object_id.to_s(8)} #{config}>"
    end

    def vocabs
      return {} unless authority?

      res = {}
      config['authority_subtypes'].each{ |pair| res[pair['subtype']] = pair['name'].downcase.gsub(' ', '-') }
      res
    end
    
    private

    attr_reader :config, :mappings

    def requires_refname?(mapping)
      return false if mapping['data_type'] == 'csrefname'
      source_type = mapping['source_type']
      return true if source_type == 'authority' || source_type == 'vocabulary'

      false
    end

    def term_group_list_key
      to_h['docstructure'][base_namespace].keys
        .select{ |key| key.end_with?('TermGroupList') }
        .first
    end
  end
end
