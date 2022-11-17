# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module CollectionspaceMigrationTools
  module AdderPreparer
    # All the preparatory stuff to successfully spin up a
    #   CMT::VocabularyTerms::Adder
    class AdderPreparer
      include Dry::Monads[:result]
      include Dry::Monads::Do.for(:call)

      class << self
        def call(...)
          self.new(...).call
        end
      end

      # @param csv_path [String] path to CSV
      def initialize(csv_path:)
        @csv_path = csv_path
      end

      def call
        puts "Setting up for vocabulary term creation..."

        handler = yield(CMT::Build::VocabHandler.call)

        row_getter = yield(CMT::Csv::FirstRowGetter.new(csv_path))
        checker = yield(CMT::Csv::FileChecker.call(csv_path, row_getter))
        row = checker[1]

        # output_dir = yield(CMT::Batch::DirPathGetter.call(mapper, batch))
        # term_reporter = yield(CMT::Csv::BatchTermReporter.new(output_dir))
        # headers = row.headers.map(&:downcase)
        # reporter = yield(CMT::Csv::BatchReporter.new(output_dir: output_dir, fields: headers, term_reporter: term_reporter))

        # writer = yield(CMT::Xml::FileWriter.new(
        #   output_dir: output_dir,
        #   action_checker: action_checker,
        #   namer: namer,
        #   s3_key_creator: obj_key_creator,
        #   reporter: reporter))

        # validator = yield(CMT::Csv::RowValidator.new(handler))
        # row_mapper = yield(CMT::Csv::RowMapper.new(handler))

        # row_processor = yield(CMT::Csv::RowProcessor.new(
        #   validator: validator,
        #   mapper: row_mapper,
        #   reporter: reporter,
        #   writer: writer
        # ))

        # processor = yield(CMT::Csv::BatchProcessor.new(
        #   csv_path: csv_path,
        #   handler: handler,
        #   first_row: row,
        #   row_processor: row_processor,
        #   term_reporter: term_reporter,
        #   output_dir: output_dir
        # ))

        Success()
      end

      private

      attr_reader :csv_path
    end
  end
end
