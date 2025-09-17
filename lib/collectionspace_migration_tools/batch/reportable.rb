# frozen_string_literal: true

require "dry/monads"
require "dry/monads/do"

module CollectionspaceMigrationTools
  module Batch
    # Mixin module with shared post-step reporting behavior
    # Classes mixing in this module must have:
    #   :process_type [String]
    #   :do_reporting [Method] returns Success or Failure
    #   :status [String] for reporting on screen
    #   :updated [Hash] capturing the values written to batches CSV for
    #     onscreen summary
    module Reportable
      include Dry::Monads[:result]
      include Dry::Monads::Do.for(:report)

      def call_and_report(report_method = :do_reporting)
        wrapped = call_wrapper(report_method)
        show_summary
        wrapped
      end

      def call_wrapper(report_method)
        puts "\nUpdating batches CSV with #{process_type} results..."
        start_reporting = Time.now

        result = send(report_method)

        elapsed = Time.now - start_reporting
        puts "Elapsed reporting time: #{elapsed}"

        result
      end

      def report(key, value, overwrite: false)
        _updated = yield(batch.populate_field(key, value, overwrite: overwrite))
        _written = yield(batch.rewrite)
        success_for(key, value)

        Success()
      end

      def show_summary
        puts summary_header
        return if updated.empty?

        updated.each { |key, value| puts "  #{key}: #{value}" }
      end

      def success_for(key, value)
        @updated[key] = value
      end

      def summary_header
        return "No values written to batches CSV" if updated.empty?

        "The following values were written to batches CSV"
      end
    end
  end
end
