# frozen_string_literal: true

require "dry/monads"
require "dry/monads/do"
require "parallel"
require "smarter_csv"

module CollectionspaceMigrationTools
  module Batch
    # Reports map warnings for a batch in a usable way
    class MapWarningsReporter
      include Dry::Monads[:result]
      include Dry::Monads::Do.for(:call)

      class << self
        def call(...)
          new(...).call
        end
      end

      def initialize(batch_id:)
        @id = batch_id
      end

      def call
        batch_dir = yield(CMT::Batch.dir(id))
        map_report = File.join(CMT.config.client.batch_dir, batch_dir,
          "mapper_report.csv")
        chunked_warnings = yield(extract_warnings(map_report))
        warnings = yield(compile_warnings(chunked_warnings))

        Success(warnings)
      end

      private

      attr_reader :id

      def compile_warnings(chunked)
        result = {}.merge(*chunked) { |key, oldval, newval| oldval + newval }
      rescue => err
        msg = "#{err.message} IN #{err.backtrace[0]}"
        Failure(CMT::Failure.new(context: "#{self.class.name}.#{__callee__}",
          message: msg))
      else
        Success(result)
      end

      def extract_warnings(path)
        return Failure("No mapper report at #{path}") unless File.exist?(path)

        process_csv_chunks(path)
      end

      def chunks(path)
        SmarterCSV.process(
          path, {
            chunk_size: CMT.config.system.csv_chunk_size,
            convert_values_to_numeric: false,
            strings_as_keys: true
          }
        )
      end

      def process_csv_chunks(path)
        result = Parallel.map(chunks(path),
          in_processes: CMT.config.system.max_processes) do |chunk|
          warning_extractor(chunk)
        end
      rescue => err
        msg = "#{err.message} IN #{err.backtrace[0]}"
        Failure(CMT::Failure.new(context: "#{self.class.name}.#{__callee__}",
          message: msg))
      else
        Success(result)
      end

      def warning_extractor(chunk)
        chunk.map { |row| row["cmt_warnings"] }
          .compact
          .map { |warnings| warnings.split(";") }
          .flatten
          .group_by { |warning| warning }
          .map { |warning, occs| [warning, occs.length] }
          .to_h
      end
    end
  end
end
