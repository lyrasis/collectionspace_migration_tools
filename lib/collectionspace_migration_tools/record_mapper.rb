# frozen_string_literal: true

require 'dry/monads'

module CollectionspaceMigrationTools
  class RecordMapper
    include Dry::Monads[:result]

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

    def to_monad
      Success(self)
    end

    def to_s
      "<##{self.class}:#{self.object_id.to_s(8)} #{config}>"
    end
    
    private

    attr_reader :config
  end
end
