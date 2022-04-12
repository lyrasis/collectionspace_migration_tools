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
      config['service_type'] == 'authority'
    end

    def base_namespace
      config['ns_uri'].keys
        .select{ |ns| ns.end_with?('_common') && ns[type_label] }
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

    def object?
      config['service_type'] == 'procedure'
    end

    def procedure?
      config['service_type'] == 'object'
    end

    def refname_columns
      mappings.select{ |mapping| requires_refname?(mapping) }
    end

    def relation?
      config['service_type'] == 'relation'
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

    def to_monad
      Success(self)
    end

    def to_s
      "<##{self.class}:#{self.object_id.to_s(8)} #{config}>"
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
