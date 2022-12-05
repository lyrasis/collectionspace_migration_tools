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
        def call(...)
          self.new(...).call
        end
      end

      ACTIONS = %w[create update delete].freeze

      # @param csv [String] path to CSV
      # @param rectype [String] record type for retrieving RecordMapper
      # @param action [String<'CREATE', 'UPDATE', 'DELETE'>]
      def initialize(csv_path:, rectype:, action:, batch: nil)
        @csv_path = csv_path
        @rectype = rectype
        if ACTIONS.any?(action)
          @action = action.upcase
        else
          puts "Action must be one of: #{ACTIONS.join(', ')}"
          exit
        end
        @batch = batch
      end

      def call
        puts "Setting up for batch processing..."

        mapper = yield CMT::Parse::RecordMapper.call(rectype)
        batch_config = yield CMT::Parse::BatchConfig.call
        handler = yield CMT::Build::DataHandler.call(mapper, batch_config)

        row_getter = yield CMT::Csv::FirstRowGetter.new(csv_path)
        checker = yield CMT::Csv::FileChecker.call(csv_path, row_getter)
        row = checker[1]

        services_path = yield CMT::Xml::ServicesApiPathGetter.call(mapper)
        action_checker = yield CMT::Xml::ServicesApiActionChecker.new(action)
        obj_key_creator = yield CMT::S3::ObjectKeyCreator.new(
          svc_path: services_path,
          batch: batch
        )

        namer = yield CMT::Xml::FileNamer.new
        output_dir = yield CMT::Batch::DirPathGetter.call(mapper, batch)
        term_reporter = yield CMT::Csv::BatchTermReporter.new(output_dir)
        headers = row.headers.map(&:downcase)
        reporter = yield CMT::Csv::BatchReporter.new(
          output_dir: output_dir,
          fields: headers,
          term_reporter: term_reporter
        )

        writer = yield CMT::Xml::FileWriter.new(
          output_dir: output_dir,
          action_checker: action_checker,
          namer: namer,
          s3_key_creator: obj_key_creator,
          reporter: reporter
        )

        validator = yield CMT::Csv::RowValidator.new(handler)
        row_mapper = yield CMT::Csv::RowMapper.new(handler)

        row_processor = yield CMT::Csv::RowProcessor.new(
          validator: validator,
          mapper: row_mapper,
          reporter: reporter,
          writer: writer
        )

        processor = yield CMT::Csv::BatchProcessor.new(
          csv_path: csv_path,
          handler: handler,
          first_row: row,
          row_processor: row_processor,
          term_reporter: term_reporter,
          output_dir: output_dir
        )

        Success(processor)
      end

      private

      attr_reader :csv_path, :rectype, :action, :batch
    end
  end
end
