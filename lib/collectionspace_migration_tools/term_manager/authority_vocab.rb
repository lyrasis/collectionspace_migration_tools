# frozen_string_literal: true

module CollectionspaceMigrationTools
  module TermManager
    class AuthorityVocab
      include TermVersionable

      attr_reader :type, :subtype, :source_version, :source_path,
        :term_field_name, :vocab_type, :init_load_mode

      # @param vocab [String]
      # @param rows [Array<Hash>]
      # @param source [CMT::TermManager::TermSource]
      def initialize(vocab, rows, source)
        vocab_parts = vocab.split("/")
        @type = vocab_parts.first
        @subtype = vocab_parts.last
        @rows = rows
        @source_version = source.current_version
        @source_path = source.path
        @term_field_name = "termDisplayName"
        @vocab_type = "authority"
        @init_load_mode = nil
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
