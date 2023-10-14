# frozen_string_literal: true

require "dry/monads"
require "dry/monads/do"
require "csv"

module CollectionspaceMigrationTools
  module VocabularyTerms
    # Handles spinning off record mapping for individual rows
    class TermsProcessor
      include Dry::Monads[:result]
      include Dry::Monads::Do.for(:call)

      # @param csv_path [String]
      # @param adder [CMT::VocabularyTerms::TermAdder]
      def initialize(csv_path:, adder:)
        @csv_path = csv_path
        @adder = adder
      end

      def call
        CSV.foreach(csv_path, headers: true) do |row|
          adder.call(row)
        end
        Success()
      rescue => err
        Failure(err)
      end

      def to_monad
        Success(self)
      end

      def to_s
        "<##{self.class}:#{object_id.to_s(8)} #{csv_path}>"
      end

      private

      attr_reader :csv_path, :adder
    end
  end
end
