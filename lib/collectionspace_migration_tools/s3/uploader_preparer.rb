# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module CollectionspaceMigrationTools
  module S3
    # All the preparatory stuff to successfully spin up a CMT::S3::Uploader
    class UploaderPreparer
      include Dry::Monads[:result]
      include Dry::Monads::Do.for(:call)

      
      class << self
        def call(csv_path:, rectype:, action:)
          self.new(csv_path: csv_path, rectype: rectype, action: action).call
        end
      end

      def initialize(file_dir:)
        @file_dir = "#{CMT.config.client.xml_dir}/#{file_dir}"
      end

      def call
        puts "Setting up for batch uploading..."
        
        client = yield(CMT::Build::S3Client.call)
        queue = yield(CMT::S3::Queue.call(file_dir))

        row_getter = yield(CMT::Csv::FirstRowGetter.new(csv_path))
        row = yield(CMT::Csv::FileChecker.call(csv_path, row_getter))

        services_path = yield(CMT::Xml::ServicesApiPathGetter.call(mapper))
        action_checker = yield(CMT::Xml::ServicesApiActionChecker.new(action))
        namer = yield(CMT::Xml::FileNamer.new(svc_path: services_path))
        output_dir = yield(CMT::Xml::DirPathGetter.call(mapper))
        term_reporter = yield(CMT::Csv::BatchTermReporter.new(output_dir))
        reporter = yield(CMT::Csv::BatchReporter.new(output_dir: output_dir, fields: row.headers, term_reporter: term_reporter))

        writer = yield(CMT::Xml::FileWriter.new(
          output_dir: output_dir,
          action_checker: action_checker,
          namer: namer,
          reporter: reporter))

        validator = yield(CMT::Csv::RowValidator.new(handler))
        row_mapper = yield(CMT::Csv::RowMapper.new(handler))
        
        row_processor = yield(CMT::Csv::RowProcessor.new(
          validator: validator,
          mapper: row_mapper,
          reporter: reporter,
          writer: writer
        ))

        processor = yield(CMT::Csv::BatchProcessor.new(
          csv_path: csv_path,
          handler: handler,
          first_row: row,
          row_processor: row_processor,
          term_reporter: term_reporter,
          output_dir: output_dir
        ))

        Success(processor)
      end

      private

      attr_reader :file_dir
    end
  end
end
