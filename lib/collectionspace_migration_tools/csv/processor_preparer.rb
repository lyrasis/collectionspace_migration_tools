# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module CollectionspaceMigrationTools
  module Csv
    # All the preparatory stuff to successfully spin up a CMT::Csv::Processor
    class ProcessorPreparer
      include Dry::Monads[:result]
      include Dry::Monads::Do.for(:call)

      
      class << self
        def call(csv_path:, rectype:, action:)
          self.new(csv_path: csv_path, rectype: rectype, action: action).call
        end
      end

      ACTIONS = %w[create update delete].freeze

      # @param csv [String] path to CSV
      # @param rectype [String] record type for retrieving RecordMapper
      # @param action [String<'CREATE', 'UPDATE', 'DELETE'>]
      def initialize(csv_path:,  rectype:, action:)
        @csv_path = csv_path
        @rectype = rectype
        if ACTIONS.any?(action)
          @action = action.upcase
        else
          puts "Action must be one of: #{ACTIONS.join(', ')}"
          exit
        end
      end

      def call
        mapper = yield(CMT::Parse::RecordMapper.call(rectype))
        handler = yield(CMT::DataHandlerBuilder.call(mapper))

        csv = yield(CMT::Csv::Checker.call(csv_path))

        services_path = yield(CMT::RecordMapper::ServicesPathGetter.call(mapper))
        namer = yield(CMT::Xml::FileNamer.new(svc_path: services_path, action: action))
        output_dir = yield(CMT::RecordMapper::DirPathGetter.call(mapper))
        row_processor = yield(CMT::Csv::RowProcessor.new(
          output_dir: output_dir,
          namer: namer
        ))

        processor = CMT::Csv::Processor.new(
          csv_path: csv,
          handler: handler,
          row_processor: row_processor
        )
        
        Success(processor)
      end

      private
      attr_reader :csv_path, :rectype, :action


    end
  end
end
