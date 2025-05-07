# frozen_string_literal: true

module CollectionspaceMigrationTools
  module TermManager
    # Mixin containing logic for identifying most-recent terms for a vocab
    #   and deltas between versions of a vocab
    module TermVersionable
      # @return [Array<Hash>] rows to load if starting from scratch
      def current
        rows.group_by { |r| r["id"] }
          .map { |_id, vrows| select_current(vrows) }
          .reject { |r| r["loadAction"] == "delete" }
      end

      def vocab_version
        @vocab_version ||= rows.map { |row| row["loadVersion"].to_i }
          .max
      end

      # @return [Array<String>] field names related to versioning
      def version_fields = %w[loadVersion loadAction id prevterm origterm
        sort-dedupe]

      private

      def select_current(vrows)
        return vrows.first if vrows.length == 1

        vrows.max_by { |r| r["loadVersion"].to_i }
      end
    end
  end
end
