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
          build_instances(instances)
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

      def build_instances(instances)
        known = project.config.instances.keys.map(&:to_s)
        chk = instances.group_by { |i| known.include?(i) }

        if chk.key?(false)
          puts "The following instances are not configured for this project: "\
            "#{chk[false].join(", ")}.\n"\
            "Configured instances include: #{known.join(", ")}"
        end

        return unless chk.key?(true)

        CMT::TM.build_instances(chk[true])
      end
    end
  end
end
