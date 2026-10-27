# frozen_string_literal: true

require "dry/monads"
require "dry/monads/do"
require "parallel"
require "smarter_csv"

module CollectionspaceMigrationTools
  module Batch
    class CsvRowCounter
      include Dry::Monads[:result]
      include Dry::Monads::Do.for(:call)

      class << self
        def call(path:, field: nil, value: nil)
          new(path).call(field: field, value: value)
        end
      end

      def initialize(path)
        @path = path
        @counts = []
      end

      # If given a field and a value, count of rows where that field is
      #   populated with that value will be returned
      # If given a field, count of rows where that field is populated will be
      #   returned
      def call(field: nil, value: nil)
        if value && !field
          return Failure("CsvRowCounter: you must specify field if you "\
                         "specify value")
        end

        reader = yield CMT::Csv::Chunker.call(path)
        _processed = yield process(reader, field, value)
        Success(counts.sum)
      end

      private

      attr_reader :path, :counts

      def add_count(ct)
        @counts << ct
      end

      def process(reader, field, value)
        reader.each_chunk do |chunk|
          if field && value
            add_count(chunk.count do |row|
                        row.key?(field) && row[field] == value
                      end)
          elsif field
            add_count(chunk.count { |row| row.key?(field) })
          else
            add_count(chunk.length)
          end
        end

        Success()
      rescue => err
        Failure(err.message)
      end

      def to_monad
        Success(self)
      end

      def to_s
        "<##{self.class}:#{object_id.to_s(8)} #{path}>"
      end
    end
  end
end
