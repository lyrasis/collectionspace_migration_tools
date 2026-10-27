# frozen_string_literal: true

require "csv"
require "dry/monads"

module CollectionspaceMigrationTools
  module Csv
    class FirstRowGetter
      include Dry::Monads[:result]

      class << self
        def call(path)
          new(path).call
        end
      end

      def initialize(path)
        @path = File.expand_path(path)
      end

      def call
        result = File.open(path) do |file|
          CSV.parse_line(file, headers: true,
            col_sep: CMT.config.system.csv_col_sep)
        end

        Success(result)
      rescue => err
        Failure(err.message)
      end

      def to_monad
        Success(self)
      end

      private

      attr_reader :path
    end
  end
end
