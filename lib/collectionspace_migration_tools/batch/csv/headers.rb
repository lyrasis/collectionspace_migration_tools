# frozen_string_literal: true

module CollectionspaceMigrationTools
  module Batch
    module Csv
      # Mixed in where access to Batch CSV headers is needed at
      #   various levels of granularity
      module Headers
        module_function

        def supplied_headers
          %w[id source_csv mappable_rectype action batch_status]
        end

        def dependency_value_lookup(steptype)
          h = {
            "map" => "rec_ct",
            "upload" => "map_oks",
            "ingest" => "upload_oks"
          }
          h[steptype]
        end

        def derived_at_add_headers
          %w[rec_ct]
        end

        # Currently superfluous, but useful in case we ever add new
        #   derived header groups
        def derived_headers
          [
            derived_at_add_headers
          ].flatten
        end

        def map_headers
          %w[mapped? dir map_errs map_oks map_warns missing_terms]
        end

        # ingest_start_time is considered to be the time the upload was
        #   initiated, so it is written by the upload process
        def upload_headers
          %w[uploaded? upload_errs upload_oks batch_prefix ingest_start_time]
        end

        def ingest_headers
          [post_ingest_headers, duplicates_headers].flatten
        end

        def post_ingest_headers
          %w[ingest_done? ingest_complete_time ingest_duration
            ingest_errs ingest_oks]
        end

        def duplicates_headers
          %w[duplicates_checked? duplicates]
        end

        def all_headers
          [
            supplied_headers,
            derived_at_add_headers,
            map_headers,
            upload_headers,
            ingest_headers
          ].flatten
        end

        def populated_if_done_headers
          [map_headers.first, upload_headers.first, ingest_check_headers.first,
            duplicates_headers.first]
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
