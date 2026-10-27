# frozen_string_literal: true

module CollectionspaceMigrationTools
  # Namespace and alias for code used/reused by Thor CLI commands
  #   in ./lib/tasks
  module CliHelpers
    ::CMT::CliHelpers = CollectionspaceMigrationTools::CliHelpers

    # @param result [Dry::Monads::Success, Dry::Monads::Failure]
    # @param successlogic [Proc] with result as its param
    # @param failurelogic [Proc] with result as its param
    def report_result(result, successlogic: nil, failurelogic: nil)
      if result.success?
        if successlogic
          successlogic.call(result)
        else
          puts result.value! unless result.value! == Dry::Monads::Unit
        end
        exit(0)
      else
        if failurelogic
          failurelogic.call(result)
          puts result.trace
        elsif result.is_a?(Exception)
          puts result.message
          puts result.backtrace
        else
          puts result.failure
          puts result.trace
        end
        exit(1)
      end
    end
  end
end
