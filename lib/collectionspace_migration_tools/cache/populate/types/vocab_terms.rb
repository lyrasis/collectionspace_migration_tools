# frozen_string_literal: true

module CollectionspaceMigrationTools
  module Cache
    module Populate
      module Types
        module VocabTerms
          def command
            :put_vocab_term
          end

          def signature(row)
            [row["vocab"], row["term"], row[cache_type.to_s]]
          end
        end
      end
    end
  end
end
