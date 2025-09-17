# frozen_string_literal: true

module CollectionspaceMigrationTools
  module TermManager
    class InstanceWorkRunner
      include Dry::Monads[:result]
      include Dry::Monads::Do.for(:run_term_list_plans)

      attr_reader :instance, :work_plan, :log

      # @param instance [CMT::TM::Instance]
      # @param work_plan [Array<CMT::TM::WorkPlan>]
      # @param log [File]
      def initialize(instance:, work_plan:, log:)
        @instance = instance
        @work_plan = work_plan
        @log = log
      end

      def call
        if work_plan.nil? || work_plan.empty?
          puts "\nNothing to do for #{instance.id}"
          return
        end

        [run_term_list_plans, run_authority_plans].flatten
          .uniq.each do |report|
            puts "\n#{instance.id} is now at version #{report[:version]} of "\
              "#{report[:source]}"
          end
      end

      private

      def grouped_plans = @grouped_plans ||=
                            work_plan.group_by { |plan| plan.vocab_type }

      def term_lists? = grouped_plans.key?("term list") &&
        !grouped_plans["term list"].empty?

      def authorities? = grouped_plans.key?("authority") &&
        !grouped_plans["authority"].empty?

      def run_term_list_plans
        return [] unless term_lists?

        instance.client.config.include_deleted = true
        handler = yield CMT::Build::VocabHandler.call(instance.client)

        grouped_plans["term list"].map do |plan|
          TermListWorkRunner.new(
            plan: plan,
            log: log,
            handler: handler
          ).call
        end
        instance.client.config.include_deleted = false
      end

      def run_authority_plans
        return [] unless authorities?

        grouped_plans["authority"].map do |plan|
          AuthorityWorkRunner.new(
            plan: plan,
            log: log
          ).call
        end
      end
    end
  end
end
