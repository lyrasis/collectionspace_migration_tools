# frozen_string_literal: true

module CollectionspaceMigrationTools
  module Cache
    module Populate
      module Types
        module AuthTerms
          def command
            :put_auth_term
          end

          def signature(row)
            [row["type"], row["subtype"], row["term"], row[cache_type.to_s]]
          end
        end
      end
    end
  end
end
