# frozen_string_literal: true

module CollectionspaceMigrationTools
  module TermManager
    class TermListVocab
      include TermVersionable

      attr_reader :vocabname

      # @param vocab [String]
      # @param rows [Array<Hash>]
      def initialize(vocab, rows)
        @vocabname = vocab
        @rows = rows
      end

      private

      attr_reader :rows
    end
  end
end
