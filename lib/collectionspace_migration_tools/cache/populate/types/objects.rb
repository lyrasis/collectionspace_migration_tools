# frozen_string_literal: true

module CollectionspaceMigrationTools
  module Cache
    module Populate
      module Types
        module Objects
          def command
            :put_object
          end

          def signature(row)
            [row["id"], row[cache_type.to_s]]
          end

          def key_val(row)
            [
              cache.send(:object_key, row["id"]),
              row[cache_type.to_s]
            ]
          end
        end
      end
    end
  end
end
