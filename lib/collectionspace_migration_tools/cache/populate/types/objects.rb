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
          alias_method :key_val, :signature
        end
      end
    end
  end
end
