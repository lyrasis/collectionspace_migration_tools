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

      def initialize(batch:, autocache:, clearcache:)
        @batch = batch
        @autocache = autocache
        @clearcache = clearcache
      end

      def call
      if autocache
        _cc = yield(CMT::Caches::Clearer.call) if clearcache
        _ac = yield(CMT::Batch::AutocacheRunner.call(batch))
      end

      puts "\n\nMAPPING"
        start_time = Time.now

        processor = yield(CMT::Csv::BatchProcessorPreparer.new(
          csv_path: batch.source_csv, rectype: batch.mappable_rectype, action: batch.action, batch: batch.id
        ).call)
        output_dir = yield(processor.call)
        puts "Elapsed time for mapping: #{Time.now - start_time}"

        report = yield(CMT::Batch::PostMapReporter.new(batch: batch, dir: output_dir).call)

        Success(report)
      end
      
      private

      attr_reader :batch, :autocache, :clearcache
    end
  end
end
