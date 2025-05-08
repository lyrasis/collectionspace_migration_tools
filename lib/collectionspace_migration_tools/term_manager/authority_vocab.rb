# frozen_string_literal: true

module CollectionspaceMigrationTools
  module TermManager
    class AuthorityVocab
      attr_reader :type, :subtype, :term_field_name

      include TermVersionable

      # @param vocab [String]
      # @param rows [Array<Hash>]
      # @param source_version [Integer]
      def initialize(vocab, rows, source_version)
        vocab_parts = vocab.split("/")
        @type = vocab_parts.first
        @subtype = vocab_parts.last
        @rows = rows
        @source_version = source_version
        @term_field_name = "termDisplayName"
      end

      private

      attr_reader :rows
    end
  end
end
