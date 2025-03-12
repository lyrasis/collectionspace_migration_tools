# frozen_string_literal: true

require "csv"
require "fileutils"
require "smarter_csv"

module CollectionspaceMigrationTools
  module Csv
    # Handles writing batch report of missing terms to CSV
    class BatchTermReporter
      include Dry::Monads[:result]

      def self.headers
        ["type", "subtype", "vocabulary", "term", "fingerprint"]
      end

      def initialize(output_dir)
        @path = "#{output_dir}/missing_terms_full.csv"
        @final_path = "#{output_dir}/missing_terms.csv"
        CSV.open(path, "wb") { |csv| csv << self.class.headers }
        @status = :created
      end

      # @param response [CollectionSpace::Mapper::Response]
      def call(response)
        missing_terms = extract_missing_terms(response)
        return if missing_terms.empty?

        CSV.open(path, "a") do |csv|
          write_rows(csv, convert_to_rows(missing_terms))
        end
      end

      def any_terms?
        readable = File.open(path)
        csv = CSV.new(readable, headers: true)
        result = !csv.shift.nil?
        readable.close
        result
      end

      def delete
        return Failure("Cannot delete report containing terms") if any_terms?

        FileUtils.rm(path) if File.exist?(path)
        if File.exist?(path)
          Failure("Empty report was not deleted")
        else
          @status = :deleted
          Success()
        end
      end

      def deduplicate
        return Success("No need to deduplicate empty report") if status == :deleted

        puts "Deduplicating missing term report for batch..."

        deduper = {}

        CSV.open(final_path, "w", write_headers: true,
          headers: %w[type subtype vocabulary term]) do |csv|
          SmarterCSV.process(path) do |chunk|
            row = chunk[0]
            fingerprint = row[:fingerprint]
            next if deduper.key?(fingerprint)

            deduper[fingerprint] = nil

            csv << [row[:type], row[:subtype], row[:vocabulary], row[:term]]
          end
        end

        FileUtils.rm(path)
      rescue => err
        msg = "#{err.message} IN #{err.backtrace[0]}"
        Failure(CMT::Failure.new(context: "#{self.class.name}.#{__callee__}",
          message: msg))
      else
        Success()
      end

      def to_monad
        Success(self)
      end

      private

      attr_reader :path, :final_path, :status

      def convert_to_rows(errs)
        errs.map do |err|
          [err[:type], err[:subtype], vocabulary(err), err[:value],
            "#{vocabulary(err)}: #{err[:value]}"]
        end
      end

      def extract_missing_terms(response)
        errs = response.errors
        return [] if errs.empty?

        errs.select { |err| err[:category] == :no_records_found_for_term }
      end

      def vocabulary(err)
        "#{err[:type]}-#{err[:subtype]}"
      end

      def write_rows(csv, rows)
        rows.each { |row| csv << row }
      end
    end
  end
end
