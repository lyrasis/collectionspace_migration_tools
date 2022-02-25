# frozen_string_literal: true

module CollectionspaceMigrationTools
  module Cache
    module Populate
      module Csids
        class AbstractCsidPopulator < CMT::Cache::Populate::AbstractPopulator
          def initialize
            @cache = CMT.csid_cache
            @start_size = @cache.size
          end
          
          private

          def cache_name
            'CSID'
          end
        end
      end
    end
  end
end
