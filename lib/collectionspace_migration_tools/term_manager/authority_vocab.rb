# frozen_string_literal: true

module CollectionspaceMigrationTools
  module TermManager
    class AuthorityVocab
      include Dry::Monads[:result]
      include Dry::Monads::Do.for(:get_current_terms_query)
      include TermVersionable

      attr_reader :vocabname, :type, :subtype, :source_version, :source_path,
        :term_field_name, :vocab_type, :init_load_mode

      # @param vocab [String]
      # @param rows [Array<Hash>]
      # @param source [CMT::TermManager::TermSource]
      def initialize(vocab, rows, source)
        @vocabname = vocab
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

      def mappable_rectype_name = @mappable_rectype_name ||=
                                    CMT::RecordTypes.valid_mappable(vocabname).value_or(nil)

      def current_terms_query = @current_terms_query ||=
                                  get_current_terms_query

      def convert_query_result_to_terms(rows)
        result = rows.map { |row| row["term"] }.compact.sort
        Success(result)
      rescue => err
        Failure(CMT::Failure.new(context: "#{name}.#{__callee__}",
          message: err.message))
      end

      def to_s
        "<##{self.class}:#{object_id.to_s(8)} type: #{type} "\
          "subtype: #{subtype}>"
      end
      alias_method :inspect, :to_s

      private

      attr_reader :rows

      def get_current_terms_query
        unless mappable_rectype_name
          return Failure("Cannot convert `#{vocabname}` to mappable rectype")
        end

        entity = yield CMT::RecordTypes.to_obj(mappable_rectype_name)
        query = yield entity.cacheable_data_query

        Success(query)
      end
    end
  end
end
