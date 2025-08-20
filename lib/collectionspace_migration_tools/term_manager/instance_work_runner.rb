# frozen_string_literal: true

module CollectionspaceMigrationTools
  module TermManager
    class InstanceWorkRunner
      include Dry::Monads[:result]
      include Dry::Monads::Do.for(:run_term_list_plans)

      attr_reader :instance, :work_plan, :log

      # @param instance [CMT::TM::Instance]
      # @param work_plan [Array<Hash>]
      # @param log [File]
      def initialize(instance:, work_plan:, log:)
        @instance = instance
        @work_plan = work_plan
        @log = log
      end

      def call
        return if work_plan.nil? || work_plan.empty?

        run_term_list_plans if term_lists?
        run_authority_plans if authorities?


      end

      private

      def grouped_plans = @grouped_plans ||=
                            work_plan.group_by { |p| p[:vocab_type] }

      def term_lists? = grouped_plans.key?("term list") &&
        !grouped_plans["term list"].empty?

      def authorities? = grouped_plans.key?("authority") &&
        !grouped_plans["authority"].empty?

      def run_term_list_plans
        handler = yield CMT::Build::VocabHandler.call(instance.client)

        grouped_plans["term list"].each do |plan|
          TermListWorkRunner.new(
            plan: plan,
            instance: instance,
            log: log,
            handler: handler
          ).call
        end
      end

      def run_authority_plans
        grouped_plans["authority"].each do |plan|
          AuthorityWorkRunner.new(
            plan: plan,
            instance: instance,
            log: log
          ).call
        end
      end
    end
  end
end
