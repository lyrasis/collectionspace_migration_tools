# frozen_string_literal: true

require 'csv'
require 'dry/monads'

module CollectionspaceMigrationTools
  module Csv
    # Handles processing of single CSV row
    class RowProcessor
      include Dry::Monads[:result]
      
      # @param output_dir [String]
      # @param namer [CMT::Xml::FileNamer]
      # @param handler [CollectionSpace::Mapper::DataHandler]
      def initialize(output_dir:, namer:, handler:)
        @output_dir = output_dir
        @namer = namer
        @handler = handler
      end
      
      # @param row [CSV::Row] with headers
      def call(row, batch)
      end

      def to_monad
        Success(self)
      end
      
      private
      
      attr_reader :output_dir, :namer, :handler

    end
  end
end

