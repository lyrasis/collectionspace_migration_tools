# frozen_string_literal: true

module CollectionspaceMigrationTools
  module Cache
    module Populate
      module Types
        module Procedures
          def command
            :put_procedure
          end
          
          def signature(row)
            [row['type'], row['id'], row[cache_type]]
          end
        end
      end
    end
  end
end
