# frozen_string_literal: true

module CollectionspaceMigrationTools
  module Cache
    module Populate
      module Refnames
        class AbstractRefnamePopulator < CMT::Cache::Populate::AbstractPopulator
          def initialize
            @cache = CMT.refname_cache
            @start_size = @cache.size
          end
          
          private

          def cache_name
            'Refname'
          end
        end
      end
    end
  end
end
