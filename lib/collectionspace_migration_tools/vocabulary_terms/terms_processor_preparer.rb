# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module CollectionspaceMigrationTools
  module VocabularyTerms
    # All the preparatory stuff to successfully spin up a
    #   CMT::VocabularyTerms::TermsProcessor
    class TermsProcessorPreparer
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

        handler = yield CMT::Build::VocabHandler.call
        row_getter = yield CMT::Csv::FirstRowGetter.new(csv_path)
        checker = yield CMT::Csv::FileChecker.call(csv_path, row_getter)
        first_row = checker[1]
        _valid = yield CMT::VocabularyTerms::TermsCsvValidator.call(first_row)
        output_dir = File.expand_path(CMT.config.client.batch_dir)
        term_reporter = yield CMT::VocabularyTerms::AdderReporter.new(
          output_dir
        )
        adder = yield CMT::VocabularyTerms::TermAdder.new(
            handler: handler,
            reporter: term_reporter
        )
        processor = yield CMT::VocabularyTerms::TermsProcessor.new(
          csv_path: csv_path,
          adder: adder
        )

        Success(processor)
      end

      private

      attr_reader :csv_path
    end
  end
end
