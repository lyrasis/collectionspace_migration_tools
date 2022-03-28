# frozen_string_literal: true

require 'csv'
require 'dry/monads'
require 'fileutils'
require 'set'
require 'smarter_csv'

module CollectionspaceMigrationTools
  module Csv
    # Handles writing batch report of missing terms to CSV
    class BatchTermReporter
      include Dry::Monads[:result]

      def initialize(output_dir)
        puts "Setting up #{self.class.name}..."
        @path = "#{output_dir}/missing_terms_full.csv"
        @final_path = "#{output_dir}/missing_terms.csv"
        CSV.open(path, 'wb'){ |csv| csv << ['type', 'subtype', 'vocabulary', 'term', 'fingerprint'] }
      end

      # @param response [CollectionSpace::Mapper::Response]
      def call(response)
        missing_terms = extract_missing_terms(response)
        return if missing_terms.empty?

        CSV.open(path, 'a') do |csv|
          write_rows(csv, convert_to_rows(missing_terms))
        end
      end

      def deduplicate
        puts "Deduplicating missing term report for batch..."

        deduper = {}
        
        CSV.open(final_path, 'w', write_headers: true, headers: %w[type subtype vocabulary term]) do |csv|
          SmarterCSV.process(path) do |chunk|
            row = chunk[0]
            fingerprint = row[:fingerprint]
            next if deduper.key?(fingerprint)

            deduper[fingerprint] = nil
            
            csv << [row[:type], row[:subtype], row[:vocabulary], row[:term]]
          end
        end

        FileUtils.rm(path)
      end
      
      def to_monad
        Success(self)
      end
      
      private
      
      attr_reader :path, :final_path

      def convert_to_rows(errs)
        errs.map{ |err| [err[:type], err[:subtype], vocabulary(err), err[:value], "#{vocabulary(err)}: #{err[:value]}"] }
      end
      
      def extract_missing_terms(response)
        errs = response.errors
        return [] if errs.empty?

        errs.select{ |err| err[:category] == :no_records_found_for_term }
      end

      def vocabulary(err)
        "#{err[:type]}/#{err[:subtype]}"
      end

      def write_rows(csv, rows)
        rows.each{ |row| csv << row }
      end
    end
  end
end
