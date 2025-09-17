# frozen_string_literal: true

module CollectionspaceMigrationTools
  module TermManager
    class ProjectWorkRunner
      attr_reader :instances, :term_sources, :log

      # @param project [CMT::TM::Project]
      # @param mode [nil, :force_current]
      def initialize(project, mode = nil)
        @project = project
        @instances = project.instances
        @term_sources = project.term_sources
        @log = project.run_log
        @mode = mode
      end

      def call
        return unless instances

        instances.each do |instance|
          work_plan = InstanceWorkPlanner.new(
            project: project,
            instance: instance,
            term_sources: term_sources,
            mode: mode
          ).call

          InstanceWorkRunner.new(
            instance: instance,
            work_plan: work_plan,
            log: log
          ).call
        end
      ensure
        log.close
      end

      private

      attr_reader :project, :mode
    end
  end
end
