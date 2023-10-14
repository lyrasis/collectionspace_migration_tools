# frozen_string_literal: true

require "csv"
require "fileutils"
require "smarter_csv"

module CollectionspaceMigrationTools
  module VocabularyTerms
    # Handles writing batch report of vocabulary term additions
    class AdderReporter
      include Dry::Monads[:result]

      def self.headers
        ["vocab", "term", "status", "message"]
      end

      def initialize(output_dir)
        timestamp = DateTime.now.strftime("%Y%m%d_%H%M")
        @path = "#{output_dir}/vocab_terms_add_#{timestamp}.csv"
        CSV.open(path, "wb") { |csv| csv << self.class.headers }
      end

      def report_failure(row, failure)
        msg = failure.is_a?(String) ? failure : failure.to_s
        to_write = [row["vocab"], row["term"], "failure", msg]
        write_row(to_write)
      end

      def report_success(row, success)
        to_write = [row["vocab"], row["term"], "success", success]
        write_row(to_write)
      end

      def to_monad
        Success(self)
      end

      private

      attr_reader :path

      def write_row(row)
        CSV.open(path, "a") do |csv|
          csv << row
        end
        row.pop
        puts row.join(" / ")
      end
    end
  end
end
