# frozen_string_literal: true

module CollectionspaceMigrationTools
  module TermManager
    class AuthorityVocab
      attr_reader :type, :subtype

      include TermVersionable

      # @param vocab [String]
      # @param rows [Array<Hash>]
      def initialize(vocab, rows)
        vocab_parts = vocab.split("/")
        @type = vocab_parts.first
        @subtype = vocab_parts.last
        @rows = rows
      end

      def current
        rows.group_by { |r| r["id"] }
          .map { |_id, vrows| select_current(vrows) }
          .reject { |r| r["loadAction"] == "delete" }
      end

      private

      attr_reader :rows

      def select_current(vrows)
        return vrows.first if vrows.length == 1

        vrows.max_by { |r| r["loadVersion"].to_i }
      end
    end
  end
end
