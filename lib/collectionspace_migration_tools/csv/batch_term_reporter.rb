# frozen_string_literal: true

require 'csv'

module CollectionspaceMigrationTools
  module Csv
    # Handles writing batch report of missing terms to CSV
    class BatchTermReporter

      def initialize(output_dir:, fields:)
        puts "Setting up #{self.class.name}..."
        @path = "#{output_dir}/missing_terms.csv"
        @csv = CSV.open(path, 'wb')
        csv << ['type', 'subtype', 'term']
      end

      def close
        csv&.close
      end

      def report_failure(result)
#        puts 'Failure!'
      end

      def report_success(result)
        puts 'Success!'
      end

      def to_monad
        Success(self)
      end
      
      private
      
      attr_reader :path, :fields, :csv

    end
  end
end
