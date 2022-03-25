# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module CollectionspaceMigrationTools
  module Csv
    # All the preparatory stuff to successfully spin up a CMT::Csv::BatchProcessor
    class BatchProcessorPreparer
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
      def initialize(csv_path:, rectype:, action:)
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
        batch_config = yield(CMT::Parse::BatchConfig.call)
        handler = yield(CMT::Build::DataHandler.call(mapper, batch_config))

        row_getter = yield(CMT::Csv::FirstRowGetter.new(csv_path))
        row = yield(CMT::Csv::FileChecker.call(csv_path, row_getter))

        services_path = yield(CMT::Xml::ServicesApiPathGetter.call(mapper))
        namer = yield(CMT::Xml::FileNamer.new(svc_path: services_path, action: action))
        output_dir = yield(CMT::Xml::DirPathGetter.call(mapper))

        reporter = yield(CMT::Csv::BatchReporter.new(output_dir: output_dir, fields: row.headers))

        validator = yield(CMT::Csv::RowValidator.new(handler, reporter))
        row_mapper = yield(CMT::Csv::RowMapper.new(handler, reporter))
        
        row_processor = yield(CMT::Csv::RowProcessor.new(
          output_dir: output_dir,
          namer: namer,
          validator: validator,
          mapper: row_mapper,
          reporter: reporter
        ))
        
        processor = yield(CMT::Csv::BatchProcessor.new(
          csv_path: csv_path,
          handler: handler,
          first_row: row,
          row_processor: row_processor,
          reporter: reporter
        ))

        Success(processor)
      end

      private
      attr_reader :csv_path, :rectype, :action


    end
  end
end
