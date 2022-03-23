# frozen_string_literal: true

require 'csv'
require 'dry/monads'

module CollectionspaceMigrationTools
  module Csv
    # Handles processing of single CSV row
    class RowProcessor
      include Dry::Monads[:result]
      
      # @param svc_path [String]
      # @param output_dir [String]
      # @param namer [CMT::Xml::FileNamer]
      def initialize(output_dir:, namer:)
        @output_dir = output_dir
        @namer = namer
      end

      # @param row [CSV::Row] with headers
      def call(row)
      end

      def to_monad
        Success(self)
      end
      
      private
      
      attr_reader :output_dir, :namer

    end
  end
end

