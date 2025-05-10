# frozen_string_literal: true

module CollectionspaceMigrationTools
  module TermManager
    class TermListVocab
      include TermVersionable

      attr_reader :vocabname, :source_version, :term_field_name, :vocab_type

      # @param vocab [String]
      # @param rows [Array<Hash>]
      # @param source_version [Integer]
      def initialize(vocab, rows, source_version)
        @rows = rows
        @vocabname = vocab
        @source_version = source_version
        @term_field_name = "displayName"
        @vocab_type = "term list"
      end

      def init_load_mode = @init_load_mode ||= set_init_load_mode

      def not_yet_loaded?(load_version) = last_load_rows(load_version).empty?

      def present_in_version?(load_version) = !not_yet_loaded?(load_version)

      def to_s
        "<##{self.class}:#{object_id.to_s(8)} vocab: #{vocabname}>"
      end
      alias_method :inspect, :to_s

      private

      attr_reader :rows

      def set_init_load_mode
        config = CMT.config.term_manager
        default = config.initial_term_list_load_mode
        overrides = config.initial_term_list_load_mode_overrides
        return default unless overrides.include?(vocabname)

        case default
        when "additive" then "exact"
        when "exact" then "additive"
        end
      end
    end
  end
end
