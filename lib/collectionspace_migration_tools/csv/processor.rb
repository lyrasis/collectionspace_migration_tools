# frozen_string_literal: true

require 'dry/monads'
require 'fileutils'
require 'smarter_csv'

module CollectionspaceMigrationTools
  module Csv
    # Handles spinning off record mapping for individual rows
    class Processor
      include Dry::Monads[:result]

      # @param csv_path [String]
      # @param mapper [Hash] parsed JSON record mapper
      # @param row_processor [CMT::Csv::RowProcessor]
      def initialize(csv_path:, handler:, row_processor: )
        @csv = CSV.new(File.open(csv_path), headers: true)
        @handler = handler
        @row_processor = row_processor
      end

      attr_reader :csv, :handler, :row_processor
      
      private

    end
  end
end
