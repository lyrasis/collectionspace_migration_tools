# frozen_string_literal: true

module CollectionspaceMigrationTools
  module TermManager
    class TermListVocab
      include TermVersionable

      attr_reader :vocabname

      # @param vocab [String]
      # @param rows [Array<Hash>]
      # @param source_version [Integer]
      def initialize(vocab, rows, source_version)
        @vocabname = vocab
        @rows = rows
        @source_version = source_version
      end

      private

      attr_reader :rows
    end
  end
end
