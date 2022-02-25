# frozen_string_literal: true

module CollectionspaceMigrationTools
  module Cache
    module Populate
      module Refnames
        class Terms < CMT::Cache::Populate::Refnames::AbstractRefnamePopulator
          private
          
          def signature(row)
            [row['type'], row['subtype'], row['label'], row['refname']]
          end
        end
      end
    end
  end
end
