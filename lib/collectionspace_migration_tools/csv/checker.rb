# frozen_string_literal: true

require 'csv'
require 'dry/monads'

module CollectionspaceMigrationTools
  module Csv
    class Checker
      include Dry::Monads[:result]

      class << self
        def call(path)
          self.new(path).call
        end
      end
      
      def initialize(path)
        @path = File.expand_path(path)
      end

      def call
        check_file.bind do
          parse_line.bind do
            Success(path)
          end
        end
      end
      
      private
      
      attr_reader :path

      def check_file
        return Success(path) if File.file?(path)

        Failure(CMT::Failure.new(context: "#{self.class.name}.#{__callee__}", message: "#{path} does not exist"))
      end

      def parse_line
        result = File.open(path){ |file| CSV.parse_line(file, headers: true, col_sep: CMT.config.client.csv_delimiter) }
      rescue StandardError => err
        Failure(CMT::Failure.new(context: "#{self.class.name}.#{__callee__}", message: err.message))
      else
        Success(result)
      end
    end
  end
end
