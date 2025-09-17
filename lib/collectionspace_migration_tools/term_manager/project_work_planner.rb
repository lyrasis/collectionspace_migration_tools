# frozen_string_literal: true

module CollectionspaceMigrationTools
  module TermManager
    class ProjectWorkPlanner
      attr_reader :instances, :term_sources

      # @param project [CMT::TM::Project]
      # @param mode [nil, :force_current]
      def initialize(project, mode = nil)
        @project = project
        @instances = project.instances
        @term_sources = project.term_sources
        @mode = mode
      end

      def call
        return unless instances

        instances.map do |instance|
          [
            instance,
            InstanceWorkPlanner.new(project: project,
              instance: instance,
              term_sources: term_sources,
                                   mode: mode).call
          ]
        end.to_h
      end

      private

      attr_reader :project, :mode
    end
  end
end
