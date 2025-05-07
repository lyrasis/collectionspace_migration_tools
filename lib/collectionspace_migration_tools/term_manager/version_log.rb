# frozen_string_literal: true

require "csv"

module CollectionspaceMigrationTools
  module TermManager
    class VersionLog
      # @param path [String]
      def initialize(path)
        @path = path
        @headers = %w[termSource instance loadVersion loadDate]
      end

      # @param term_source [CMT::TermManager::TermSource]
      # @param instance [CMT::TermManager::Instance]
      # @return [Integer, nil] latest version of given term source loaded for
      #   given instance
      def version_for(term_source, instance)
        return if missing?

        data.select do |row|
          row["termSource"] == term_source.path &&
            row["instance"] == instance.id
        end.map { |row| row["loadVersion"].to_i }
          .max
      end

      # @param term_source [CMT::TermManager::TermSource]
      # @param instance [CMT::TermManager::Instance]
      def record_load(term_source, instance)
      end

      private

      attr_reader :path, :headers

      def data
        @data ||= (missing? ? [] : CSV.parse(File.read(path), headers: true))
      end

      def create_log
        CSV.open(path, "w", headers: headers, write_headers: true)
      end

      def missing? = @missing ||= !File.exist?(path)
    end
  end
end
