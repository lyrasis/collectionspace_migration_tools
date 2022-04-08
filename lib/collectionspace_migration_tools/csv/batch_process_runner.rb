# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module CollectionspaceMigrationTools
  module Csv
    # Wraps building and calling of processor with any dependencies
    class BatchProcessRunner
      include Dry::Monads[:result]
      include Dry::Monads::Do.for(:call)

      class << self
        def call(...)
          self.new(...).call
        end
      end

      def initialize(csv:, rectype:, action:, batch: nil)
        @csv = csv
        @rectype = rectype
        @action = action
        @batch = batch
      end

      def call
        start_time = Time.now
        
        processor = yield(CMT::Csv::BatchProcessorPreparer.new(csv_path: csv, rectype: rectype, action: action).call)
        processed = yield(processor.call)
        puts "Total time: #{Time.now - start_time}"

        Success()
      end
      
      private

      attr_reader :csv, :rectype, :action, :batch
    end
  end
end
