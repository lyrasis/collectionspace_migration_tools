# frozen_string_literal: true

module CollectionspaceMigrationTools
  module TermManager
    class ProjectWorkPlanner
      attr_reader :instances, :term_sources

      # @param project [CMT::TM::Project]
      # @param instances [:all, Array[<String>]]
      # @param term_sources [:all, Array[<String>]]
      def initialize(project:, instances: nil, term_sources: nil)
        @project = project
        @instances = if instances
          CMT::TM.build_instances(instances)
        else
          project.instances
        end
        @term_sources = if term_sources
          CMT::TM.build_term_sources(term_sources)
        else
          project.term_sources
        end
      end

      def call
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
