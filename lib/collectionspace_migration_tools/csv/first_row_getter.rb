# frozen_string_literal: true

require 'csv'
require 'dry/monads'

module CollectionspaceMigrationTools
  module Csv
    class FirstRowGetter
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
        result = File.open(path){ |file| CSV.parse_line(file, headers: true, col_sep: CMT.config.client.csv_delimiter) }
      rescue StandardError => err
        Failure(CMT::Failure.new(context: "#{self.class.name}.#{__callee__}", message: err.message))
      else
        Success(result)
      end

      def to_monad
        Success(self)
      end
      
      private
      
      attr_reader :path
    end
  end
end
