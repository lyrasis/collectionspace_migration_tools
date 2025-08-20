# frozen_string_literal: true

module CollectionspaceMigrationTools
  module TermManager
    class ProjectWorkPlanner
      attr_reader :instances, :term_sources

      # @param project [CMT::TM::Project]
      def initialize(project)
        @project = project
        @instances = project.instances
        @term_sources = project.term_sources
      end

      def call
        return unless instances

        instances.map do |instance|
          [
            instance,
            InstanceWorkPlanner.new(project: project,
              instance: instance,
              term_sources: term_sources).call
          ]
        end.to_h
      end

      private

      attr_reader :project
    end
  end
end
