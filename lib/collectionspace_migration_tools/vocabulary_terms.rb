# frozen_string_literal: true

module CollectionspaceMigrationTools
  module VocabularyTerms
    extend Dry::Monads[:result, :do]

    module_function

    def add(csv_path)
      processor = yield CMT::VocabularyTerms::TermsProcessorPreparer.call(
        csv_path: CMT.get_csv_path(csv_path)
      )
      _result = yield processor.call

      Success()
    end
  end
end
