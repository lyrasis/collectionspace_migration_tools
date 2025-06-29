# frozen_string_literal: true

require "roo"

module CollectionspaceMigrationTools
  module TermManager
    class TermSource
      attr_reader :path

      # @param path [String]
      def initialize(path)
        @path = path
      end

      def missing? = @missing ||= !File.exist?(path)

      def type = @type ||= get_type

      def workbook
        return nil if missing?

        @workbook ||= Roo::Excelx.new(path)
      end

      def sheet
        return nil if missing?

        @sheet ||= workbook.sheet("termData")
      end

      def rows
        return nil if missing?

        @rows ||= get_rows
      end

      def current_version
        return nil if missing?

        @current_version ||= rows.map { |row| row["loadVersion"].to_i }
          .max
      end

      def vocabs
        return [] if missing?

        @vocabs ||= build_vocabs
      end

      private

      def get_type
        return :authority if CMT.config
          .term_manager.authority_sources
          .include?(path)

        :term_list
      end

      def get_rows
        rows = sheet.parse(headers: true)
        rows.shift
        rows
      end

      def build_vocabs
        return build_authority_vocabs if type == :authority

        build_term_list_vocabs
      end

      def build_authority_vocabs
        rows.group_by do |row|
          "#{row["authorityType"]}/#{row["authoritySubtype"]}"
        end
          .map do |vocab, rows|
            AuthorityVocab.new(vocab, rows, current_version)
          end
      end

      def build_term_list_vocabs
        rows.group_by { |row| row["term_list_shortIdentifier"] }
          .map { |vocab, rows| TermListVocab.new(vocab, rows, current_version) }
      end
    end
  end
end
