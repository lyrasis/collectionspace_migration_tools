# frozen_string_literal: true

module CollectionspaceMigrationTools
  module TermManager
    class InstanceWorkPlanner
      # @param project [CMT::TM::Project]
      # @param instance [CMT::TM::Instance]
      # @param term_sources [Array<CMT::TM::TermSource>]
      # @param mode [nil, :force_current]
      def initialize(project:, instance:, term_sources:, mode: nil)
        @project = project
        @instance = instance
        @term_sources = term_sources
        @mode = mode
      end

      def call
        term_sources.map { |ts| plans_for_term_source(ts) }
          .flatten
          .reject(&:nothing_to_do?)
      end

      private

      attr_reader :project, :instance, :term_sources, :mode

      def plans_for_term_source(source)
        load_version = project.version_log.version_for(source, instance)
        source.vocabs
          .map do |vocab|
            CMT::TermManager::WorkPlan.new(
              instance: instance,
              load_version: load_version,
              vocab: vocab,
              mode: mode
            ).call
          end
      end
    end
  end
end
