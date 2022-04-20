# frozen_string_literal: true

module CollectionspaceMigrationTools
  module Batch
    # mixin containing methods for dealing with data about batch ingest check
    module Ingestable
      include CMT::Batch::Steppable
      include Dry::Monads::Do.for(:rollback_ingest)

      def rollback_ingest
        rolled = yield(rollback_step('ingest'))

        Success('Ingest information rolled back. Note this does NOT undo any ingest operations that occurred')
      end

      def ingest_step_headers
        CMT::Batch::Csv::Headers.ingest_headers
      end
      
      def ingest_step_report_paths
        ["#{dirpath}/ingest_report.csv"]
      end

      def ingest_next_step
        CMT::Batch::Csv::Headers.duplicates_headers.first
      end

      def ingestable?
        check_status('ingest')
      end
    end
  end
end
