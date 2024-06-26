# frozen_string_literal: true

require "fileutils"

module CollectionspaceMigrationTools
  module Batch
    # mixin containing methods for dealing with data about batch mapping jobs
    module Mappable
      include CMT::Batch::Steppable
      include Dry::Monads::Do.for(:rollback_map)

      def rollback_map
        _rolled = yield(rollback_step("map"))
        _dir_del = yield(delete_batch_dir)

        Success("Mapping data rolled back")
      end

      def map_step_headers
        CMT::Batch::Csv::Headers.map_headers
      end

      def map_step_report_paths
        ["mapping_report.csv", "missing_terms.csv"].map do |report|
          "#{dirpath}/#{report}"
        end
      end

      def map_next_step
        CMT::Batch::Csv::Headers.upload_headers.first
      end

      def map_previous_status = "added"

      def mappable?
        check_status("map")
      end
    end
  end
end
