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

      def initialize(csv:, rectype:, action:)
        @csv = csv
        @rectype = rectype
        @action = action
      end

      def call
        start_time = Time.now

        processor = yield(CMT::Csv::BatchProcessorPreparer.new(csv_path: csv, rectype: rectype, action: action).call)
        output_dir = yield(processor.call)
        puts "Total time: #{Time.now - start_time}"

        Success(output_dir)
      end
      
      private

      attr_reader :csv, :rectype, :action
    end
  end
end
