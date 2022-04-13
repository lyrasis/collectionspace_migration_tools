# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module CollectionspaceMigrationTools
  module Batch
    # Wraps building and calling of processor with any dependencies
    class MapRunner
      include Dry::Monads[:result]
      include Dry::Monads::Do.for(:call)

      class << self
        def call(...)
          self.new(...).call
        end
      end

      def initialize(batch:, csv:, rectype:, action:)
        @batch = batch
        @csv = csv
        @rectype = rectype
        @action = action
      end

      def call
        puts "\n\nMAPPING"
        start_time = Time.now

        processor = yield(CMT::Csv::BatchProcessorPreparer.new(csv_path: csv, rectype: rectype, action: action, batch: batch).call)
        output_dir = yield(processor.call)
        puts "Elapsed time for mapping: #{Time.now - start_time}"

        Success(output_dir)
      end
      
      private

      attr_reader :batch, :csv, :rectype, :action
    end
  end
end
