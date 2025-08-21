# frozen_string_literal: true

module CollectionspaceMigrationTools
  module TermManager
    # Abstract class with shared logic for term list and authority work
    #   runners.
    # @note Concrete classes must define the following methods: type,
    #   subtype, call
    class VocabWorkRunner
      attr_reader :instance, :plan, :log

      # @param plan [Hash]
      # @param instance [CMT::TM::Instance]
      # @param log [File]
      # @param handler [nil, CollectionSpace::Mapper::VocabularyTerms::Handler]
      def initialize(plan:, instance:, log:, handler: nil)
        @plan = plan
        @instance = instance
        @log = log
        @handler = handler
        @log_prefix = "#{instance.id}|#{plan[:vocab_type]}|"
        @error_count = 0
      end

      def service_path = @service_path ||=
                           CollectionSpace::Service.get(type: type,
                             subtype: subtype)[:path]

      private

      attr_reader :handler, :log_prefix, :error_count

      def rows_by_action
        @rows_by_action ||= plan[:rows].group_by { |r| r["loadAction"] }
      end

      def add_error = @error_count += 1

      def finish
        warn_of_errors

        {
          source: plan[:term_source_path],
          version: plan[:term_source_version]
        }
      end

      def warn_of_errors
        return if error_count == 0

        puts "#{error_count} errors for #{instance.id} #{type}/#{subtype}."
      end
    end
  end
end
