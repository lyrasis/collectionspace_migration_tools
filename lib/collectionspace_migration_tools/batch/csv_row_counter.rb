# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'
require 'parallel'
require 'smarter_csv'

module CollectionspaceMigrationTools
  module Batch
    class CsvRowCounter
      include Dry::Monads[:result]
      include Dry::Monads::Do.for(:call)

      class << self
        def call(path)
          self.new(path).call
        end
      end
      
      def initialize(path)
        @path = path
        @counts = []
      end

      def call
        _processed = yield(process)
        Success(counts.sum)
      end
      
      private
      
      attr_reader :path, :counts

      def add_count(ct)
        @counts << ct
      end

      def process
        SmarterCSV.process(path, {
            chunk_size: CMT.config.system.csv_chunk_size,
            convert_values_to_numeric: false,
            strings_as_keys: true
          }){ |chunk| add_count(chunk.length) }
      rescue StandardError => err
        msg = "#{err.message} IN #{err.backtrace[0]}"
        Failure(CMT::Failure.new(context: "#{self.class.name}.#{__callee__}", message: msg))
      else
        Success()
      end

      def to_monad
        Success(self)
      end
      
      def to_s
        "<##{self.class}:#{self.object_id.to_s(8)} #{path}>"
      end

    end
  end
end
