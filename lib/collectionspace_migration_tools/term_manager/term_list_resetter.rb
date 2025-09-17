# frozen_string_literal: true

module CollectionspaceMigrationTools
  module TermManager
    class TermListResetter
      include Dry::Monads[:result]
      # include Dry::Monads::Do.for()

      attr_reader :instances, :log

      # @param project [CMT::TM::Project]
      def initialize(project)
        @project = project
        @instances = project.instances
        @log = project.run_log
      end

      def call
        return unless instances

        instances.each do |i|
          InstanceWorkRunner.new(
            instance: i,
            work_plan: get_work_plans(i),
            log: log
          ).call
        end
      end

      private

      attr_reader :project

      def get_work_plans(i)
        vocabs.map do |v|
          WorkPlan.new(instance: i, load_version: nil, vocab: v).call
        end
      end

      def vocabs
        @vocabs ||= get_vocabs
      end

      def get_vocabs
        project.term_sources
          .select { |src| src.type == :term_list }
          .map { |src| src.vocabs }
          .flatten
          .select { |vocab| vocab.init_load_mode == "exact" }
      end
    end
  end
end
