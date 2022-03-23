# frozen_string_literal: true

module CollectionspaceMigrationTools
  module RecordTypes
    module_function

    def authority
      %w[citation concept location material organization person place taxon work]
    end

    def mappable
      Dir.new(CMT.config.client.mapper_dir)
        .children
        .map{ |fn| fn.delete_prefix("#{CMT.config.client.profile}_#{CMT.config.client.profile_version}_") }
        .map{ |fn| fn.delete_suffix(".json") }
        .sort
    end
    
    def procedures
      {
        'acq' => 'acquisitions',
        'claim' => 'claims',
        'cc' => 'conditionchecks',
        'cons' => 'conservation',
        'exh' => 'exhibitions',
        'group' => 'groups',
        'ins' => 'insurances',
        'intake' => 'intakes',
        'lin' => 'loansin',
        'lout' => 'loansout',
        'media' => 'media',
        'lmi' => 'movements',
        'exit' => 'objectexit',
        'osteo' => 'osteology',
        'pot' => 'pottags',
        'prop' => 'propagations',
        'tran' => 'transports',
        'uoc' => 'uoc',
        'val' => 'valuationcontrols'
      }
    end
      
  end
end
