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

          def key_val(row)
            [
              cache.send(:vocab_term_key, row["vocab"], row["term"]),
              row[cache_type.to_s]
            ]
          end
        end
      end
    end
  end
end
