# frozen_string_literal: true

module CollectionspaceMigrationTools
  module TermManager
    class TermListWorkRunner < VocabWorkRunner
      def type = "vocabularies"

      def subtype = plan[:vocab_name]

      def call
        rows_by_action["create"]&.each { |t| create_term(t) }
        rows_by_action["update"]&.each { |t| update_term(t) }
        rows_by_action["delete"]&.each { |t| delete_term(t) }
        finish
      end

      private

      def create_term(termhash)
        opt_fields = add_opt_fields.map { |fld| [fld, termhash[fld]] }
          .to_h
          .compact
        opts = opt_fields.empty? ? nil : opt_fields
        term = termhash["term"]
        result = handler.add_term(vocab: subtype, term: term, opt_fields: opts)
        to_log(result, :create, term)
      end

      def add_opt_fields = @add_opt_fields ||=
                             CollectionSpace::Mapper::VocabularyTerms::ADD_OPT_FIELDS

      def update_term(term)
      end

      def delete_term(termhash)
        term = termhash["origterm"]
        result = handler.delete_term(vocab: subtype, term: term)
        to_log(result, :delete, term)
      end

      def to_log(result, action, term)
        prefix = "#{log_prefix}#{subtype}|#{action}|#{term}|"
        entry = result.either(
          ->(success) { "#{prefix}SUCCESS|#{success}\n" },
          ->(failure) do
            add_error
            message = if failure.is_a?(String)
              failure
            elsif failure.is_a?(CollectionSpace::Response)
              "#{failure.status_code} #{failure.parsed}"
            else
              "UNHANDLED_FAILURE_TYPE: #{failure.inspect}"
            end
            "#{prefix}FAILURE|#{message}\n"
          end
        )
        log << entry
      end
    end
  end
end
