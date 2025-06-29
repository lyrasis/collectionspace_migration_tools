# frozen_string_literal: true

module CollectionspaceMigrationTools
  module TermManager
    class AuthorityVocab
      attr_reader :type, :subtype, :term_field_name, :vocab_type

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
        @vocab_type = "authority"
      end

      def vocabname = "#{type}/#{subtype}"

      def to_s
        "<##{self.class}:#{object_id.to_s(8)} type: #{type} "\
          "subtype: #{subtype}>"
      end
      alias_method :inspect, :to_s

      private

      attr_reader :rows
    end
  end
end
