# frozen_string_literal: true

module CollectionspaceMigrationTools
  class RecordMapper
    attr_reader :to_h

    def initialize(hash)
      @to_h = hash
      @config = to_h['config']
    end

    def authority?
      config['service_type'] == 'authority'
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
    
    def subtype
      config['authority_subtype'] if authority?
    end

    def service_path
      config['service_path']
    end
    
    private

    attr_reader :config
  end
end
