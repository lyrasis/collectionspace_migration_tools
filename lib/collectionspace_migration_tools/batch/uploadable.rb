# frozen_string_literal: true

require "fileutils"

module CollectionspaceMigrationTools
  module Batch
    # mixin containing methods for dealing with data about batch uploads
    module Uploadable
      include CMT::Batch::Steppable
      include Dry::Monads::Do.for(:rollback_upload)

      def rollback_upload
        _rolled = yield(rollback_step("upload"))

        Success("Upload information rolled back. Note this does NOT undo any ingest operations triggered by an upload")
      end

      def upload_step_headers
        CMT::Batch::Csv::Headers.upload_headers
      end

      def upload_step_report_paths
        ["#{dirpath}/upload_report.csv"]
      end

      def upload_next_step
        CMT::Batch::Csv::Headers.ingest_headers.first
      end

      def upload_previous_status = "mapped"

      def uploadable?
        check_status("upload")
      end
    end
  end
end
