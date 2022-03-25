# frozen_string_literal: true

require 'csv'
require 'dry/monads'

module CollectionspaceMigrationTools
  module Csv
    # Handles writing batch report CSV
    class BatchReporter
      include Dry::Monads[:result]

      def initialize(output_dir:, fields:)
        puts "Setting up #{self.class.name}..."
        @path = "#{output_dir}/mapper_report.csv"
        @fields = [fields, 'warnings', 'errors'].flatten
        @csv = CSV.open(path, 'wb')
        csv << fields
      end

      def close
        csv&.close
      end

      def report_failure(result)
        puts 'Failure!'
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
