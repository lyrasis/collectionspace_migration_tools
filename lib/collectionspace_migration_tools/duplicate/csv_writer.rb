# frozen_string_literal: true

require "csv"

module CollectionspaceMigrationTools
  module Duplicate
    # Handles writing duplicate report CSV
    class CsvWriter
      include Dry::Monads[:result]

      class << self
        def call(...)
          new(...).call
        end
      end

      attr_reader :path

      # PG::Result allows you to enumerate over query result rows, where each
      #   row is a Hash
      # @param path [String] path to write report to
      # @param duplicates [PG::Result] keys of objects still in S3 bucket
      def initialize(path:, duplicates:)
        @path = path
        @duplicates = duplicates
        @headers = get_headers
        CSV.open(path, "wb") { |csv| csv << @headers }
      end

      def call
        CSV.open(path, "a") do |csv|
          duplicates.each { |row| csv << row.values_at(*headers) }
        end
      rescue => err
        msg = "#{err.message} IN #{err.backtrace[0]}"
        Failure(CMT::Failure.new(context: "#{self.class.name}.#{__callee__}",
          message: msg))
      else
        Success(path)
      end

      def to_monad
        Success(self)
      end

      private

      attr_reader :duplicates, :headers

      def get_headers
        duplicates[0].keys
      end
    end
  end
end
