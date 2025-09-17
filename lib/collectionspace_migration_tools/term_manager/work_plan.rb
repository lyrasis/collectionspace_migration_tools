# frozen_string_literal: true

module CollectionspaceMigrationTools
  module TermManager
    class WorkPlan
      include Dry::Monads[:result]
      include Dry::Monads::Do.for(:get_current_terms)

      attr_reader :instance, :vocab, :vocab_type, :vocab_name,
        :term_source_version, :term_source_path,
        :creates, :updates, :deletes

      # @param instance [CMT::TM::Instance]
      # @param load_version [nil, Integer] last loaded version of vocab
      # @param vocab [CMT::TM::TermListVocab, CMT::TM::AuthorityVocab]
      # @param mode [nil, :force_current]
      def initialize(instance: instance, load_version: load_version,
                     vocab: vocab, mode: nil)
        @instance = instance
        @load_version = load_version
        @vocab = vocab
        @mode = mode
        @vocab_type = vocab.vocab_type
        @vocab_name = vocab.vocabname
        @term_source_version = vocab.source_version
        @term_source_path = vocab.source_path
        @init_load_mode = vocab.init_load_mode
        @creates = []
        @updates = []
        @deletes = []
      end

      def call
        if mode == :force_current
          forced_work_plan
        else
          default_work_plan
        end
      end

      def anything_to_do? = !nothing_to_do?

      def nothing_to_do? = [creates, updates, deletes].reject(&:empty?).empty?

      def term_list_status = @term_list_status ||= get_status

      def current_terms
        return @current_terms if instance_variable_defined?(:@current_terms)

        set_current_terms
      end

      def to_h
        result = instance_variables.map do |iv|
          next if [:@instance, :@vocab, :@delta, :@current_terms].include?(iv)

          [
            iv.to_s.delete_prefix("@").to_sym,
            instance_variable_get(iv)
          ]
        end.compact.to_h
        result[:instance] = instance.id
        result
      end

      private

      attr_reader :load_version, :mode, :init_load_mode

      def forced_work_plan
        terms = vocab.current
        if init_load_mode == "exact"
          forced_exact_work_plan(terms)
        else
          forced_additive_work_plan(terms)
        end
      end

      def forced_exact_work_plan(terms)
        forced_additive_work_plan(terms)
        add_exact_deletes
        self
      end

      def forced_additive_work_plan(terms)
        terms.each { |term| assign_term(term) }
        self
      end

      def assign_term(term)
        return if current_terms.include?(term["term"])

        if term["term"] == term["origterm"]
          creates << term
          return
        end

        if current_terms.include?(term["origterm"])
          updates << term
        else
          creates << term
        end
      end

      def default_work_plan
        return self if delta.empty?

        populate_action_instance_variables

        if term_list_status == :initial && init_load_mode == "exact"
          add_exact_deletes
        end

        clean_creates unless creates.empty?

        self
      end

      def delta = @delta ||= vocab.delta(load_version)

      def populate_action_instance_variables
        grouped = delta.group_by { |t| t["loadAction"] }
        %w[create update delete].each do |action|
          next unless grouped.key?(action)

          instance_variable_set(:"@#{action}s", grouped[action])
        end
        return unless term_list_status == :initial

        @creates = creates + updates
        @updates = []
      end

      def clean_creates
        return if current_terms.empty?

        @creates = creates.reject do |t|
          current_terms.include?(t[term_key].split("|").first)
        end
      end

      def terms_to_keep
        keeping = []
        [creates, updates].each do |terms|
          terms.each do |term|
            keeping << term[term_key]
            keeping << term["origterm"]
          end
        end
        keeping.compact.uniq
      end

      def add_exact_deletes
        ok = vocab.current.map { |r| r["term"] }
        keeping = terms_to_keep
        current_terms.each do |term|
          next if keeping.include?(term)
          next if ok.include?(term)

          deletes << {
            "loadAction" => "delete",
            term_key => term,
            "origterm" => term
          }
        end
      end

      def term_key = case vocab_type
                     when "term list"
                       "term"
                     when "authority"
                       "termDisplayName"
                     end

      def get_status
        return :up_to_date if nothing_to_do?
        return :initial if vocab.not_yet_loaded?(load_version)

        :delta
      end

      def client = instance.client

      def set_current_terms
        get_current_terms.either(
          ->(success) { @current_terms = success },
          ->(failure) do
            warn("Could not retrieve current terms for "\
                 "#{vocab.type}/#{vocab.subtype}: #{failure}")
            @current_terms = []
          end
        )
      end

      def get_current_terms
        query = yield vocab.current_terms_query
        result = yield CMT::Database::ExecuteQuery.call(query, instance.id.to_s)
        terms = yield vocab.convert_query_result_to_terms(result)

        Success(terms)
      end
    end
  end
end
