# frozen_string_literal: true

module CollectionspaceMigrationTools
  module TermManager
    class TermListVocab
      include Dry::Monads[:result]
      include Dry::Monads::Do.for(:get_current_terms_query)
      include TermVersionable

      attr_reader :vocabname, :source_version, :source_path, :term_field_name,
        :vocab_type

      # @param vocab [String]
      # @param rows [Array<Hash>]
      # @param source [CMT::TermManager::TermSource]
      def initialize(vocab, rows, source)
        @term_field_name = "displayName"
        @rows = rows.map do |r|
          r[term_field_name] = r["term"]
          r
        end
        @vocabname = vocab
        @source_version = source.current_version
        @source_path = source.path
        @vocab_type = "term list"
      end

      def type = "vocabulary"

      def subtype = vocabname

      def init_load_mode = @init_load_mode ||= set_init_load_mode

      def present_in_version?(load_version) = !not_yet_loaded?(load_version)

      def current_terms_query = @current_terms_query ||=
                                  get_current_terms_query

      def convert_query_result_to_terms(rows)
        result = rows.map do |row|
          if row["vocab"] == vocabname
            row["term"]
          end
        end.compact.sort
        Success(result)
      rescue => err
        Failure(CMT::Failure.new(context: "#{name}.#{__callee__}",
          message: err.message))
      end

      def to_s
        "<##{self.class}:#{object_id.to_s(8)} vocab: #{vocabname}>"
      end
      alias_method :inspect, :to_s

      private

      attr_reader :rows

      def get_current_terms_query
        entity = yield CMT::RecordTypes.to_obj(type)
        query = yield entity.cacheable_data_query

        Success(query)
      end

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
