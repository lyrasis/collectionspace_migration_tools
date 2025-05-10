# frozen_string_literal: true

module CollectionspaceMigrationTools
  module TermManager
    class TermListVocab
      include TermVersionable

      attr_reader :vocabname, :source_version, :term_field_name

      # @param vocab [String]
      # @param rows [Array<Hash>]
      # @param source_version [Integer]
      def initialize(vocab, rows, source_version)
        @rows = rows
        @vocabname = vocab
        @source_version = source_version
        @term_field_name = "displayName"
      end


      def to_s
        "<##{self.class}:#{object_id.to_s(8)} vocab: #{vocabname}>"
      end
      alias_method :inspect, :to_s

      private

      attr_reader :rows
    end
  end
end
