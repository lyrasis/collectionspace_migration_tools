# frozen_string_literal: true

require "csv"

module CollectionspaceMigrationTools
  module Batch
    class RefnameCacheDependencyIdentifier
      include Dry::Monads[:result]

      class << self
        def call(...)
          new(...).call
        end
      end

      def initialize(headers:, mapper:)
        @headers = headers.map(&:downcase)
        @mappings = mapper.refname_columns
        @subtype_mappings =
          CMT::RecordTypes.authority_subtype_machine_to_human_label_mapping
      end

      def call
        return Success("") if mappings.empty?

        res = mappings.select do |mapping|
          headers.any?(mapping["datacolumn"].downcase)
        end
          .map { |mapping| extract_cacheable(mapping) }
          .uniq
          .map { |rectype| CMT::RecordTypes.to_obj(rectype) }

        failures = res.select(&:failure?)

        if failures.empty?
          final = res.map(&:value!)
            .map(&:to_s)
            .join("|")

          Success(final)
        else
          fail_report = failures.map { |f| f.failure.to_s }
            .join("|")
          msg = "One or more fields in source CSV is populated with an "\
            "authority that cannot be converted for caching:"
          Failure(
            "#{self.class.name.split("::")[-1]} ERROR: #{msg} #{fail_report}"
          )
        end
      end

      private

      attr_reader :headers, :mappings, :subtype_mappings

      def extract_cacheable(mapping)
        return "vocabulary" if mapping["source_type"] == "vocabulary"

        mapping["source_name"].sub("/", "-")
      end
    end
  end
end
