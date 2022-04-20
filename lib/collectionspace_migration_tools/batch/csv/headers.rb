# frozen_string_literal: true

module CollectionspaceMigrationTools
  module Batch
    module Csv
      # Mixed in where access to Batch CSV headers is needed at various levels of granularity
      module Headers
        module_function

        def supplied_headers
          %w[id source_csv mappable_rectype action]
        end

        def derived_at_add_headers
          %w[rec_ct]
        end

        # currently superfluous, but useful in case we ever add new derived header groups
        def derived_headers
          [
            derived_at_add_headers
          ].flatten
        end
        
        def map_headers
          %w[mapped? dir map_errs map_oks map_warns]
        end

        def upload_headers
          %w[uploaded? upload_errs upload_oks batch_prefix]
        end

        def ingest_headers
          %w[ingest_done? ingest_errs ingest_oks]
        end

        def duplicates_headers
          %w[duplicates_checked? duplicates]
        end

        def final_headers
          %w[done?]
        end
        
        def all_headers
          [
            supplied_headers,
            derived_at_add_headers,
            map_headers,
            upload_headers,
            ingest_headers,
            duplicates_headers,
            final_headers
          ].flatten
        end

        # requires class mixing this in to have `table` method defined
        def check_headers
          return Success() if table.headers == all_headers

          Failure([:update_csv_columns])
        end
      end
    end
  end
end
