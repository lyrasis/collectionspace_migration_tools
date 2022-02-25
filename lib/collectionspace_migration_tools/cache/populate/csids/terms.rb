# frozen_string_literal: true

module CollectionspaceMigrationTools
  module Cache
    module Populate
      module Csids
        class Terms < CMT::Cache::Populate::Csids::AbstractCsidPopulator
          private
          
          def signature(row)
            [row['type'], row['subtype'], row['label'], row['csid']]
          end
        end
      end
    end
  end
end
