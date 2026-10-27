# frozen_string_literal: true

require "smarter_csv"
require "dry/monads"

module CollectionspaceMigrationTools
  module Csv
    # Wrapper around SmarterCSV Reader
    class Chunker
      include Dry::Monads[:result]

      class << self
        def call(path, opts = nil)
          new(path, opts).call
        end
      end

      DEFAULT_OPTS = {
        col_sep: CMT.config.system.csv_col_sep,
        row_sep: CMT.config.system.csv_row_sep,
        chunk_size: CMT.config.system.csv_chunk_size,
        quote_escaping: CMT.config.system.csv_quote_escaping,
        quote_boundary: CMT.config.system.csv_quote_boundary,
        strip_chars_from_headers:
          CMT.config.system.csv_strip_chars_from_headers,
        convert_values_to_numeric:
          CMT.config.system.csv_convert_values_to_numeric,
        strings_as_keys: CMT.config.system.csv_strings_as_keys
      }

      def initialize(path, opts = nil)
        @path = File.expand_path(path)
        @opts = if opts
          DEFAULT_OPTS.merge(opts)
        else
          DEFAULT_OPTS
        end
      end

      # @return [SmarterCSV::Reader]
      def call
        return Failure("No such file: #{path}") unless File.exist?(path)

        result = SmarterCSV::Reader.new(path, opts)

        Success(result)
      rescue => err
        Failure(err.message)
      end

      def to_monad
        Success(self)
      end

      private

      attr_reader :path, :opts
    end
  end
end
