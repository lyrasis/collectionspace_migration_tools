# frozen_string_literal: true

module CollectionspaceMigrationTools
  module TermManager
    class InstanceWorkPlanner
      # @param project [CMT::TM::Project]
      # @param instance [CMT::TM::Instance]
      # @param term_sources [Array<CMT::TM::TermSource>]
      def initialize(project:, instance:, term_sources:)
        @project = project
        @instance = instance
        @term_sources = term_sources
      end

      def call
        term_sources.map do |source|
          load_version = project.version_log.version_for(source, instance)
          source.vocabs.map { |vocab| vocab.work_plan(load_version) }
            .compact
        end.flatten
      end

      private

      attr_reader :project, :instance, :term_sources
    end
  end
end
