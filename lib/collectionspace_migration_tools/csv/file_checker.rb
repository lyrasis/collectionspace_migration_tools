# frozen_string_literal: true

require 'csv'
require 'dry/monads'
require 'dry/monads/do'

module CollectionspaceMigrationTools
  module Csv
    class FileChecker
      include Dry::Monads[:result]
      include Dry::Monads::Do.for(:call)

      class << self
        def call(path, row_getter)
          self.new(path, row_getter).call
        end
      end
      
      def initialize(path, row_getter)
        @path = File.expand_path(path)
        @row_getter = row_getter
      end

      def call
        _csv = yield(check_file)
        row = yield(row_getter.call)
        
        Success([path, row])
      end
      
      private
      
      attr_reader :path, :row_getter

      def check_file
        return Success(path) if File.file?(path)

        Failure(CMT::Failure.new(context: "#{self.class.name}.#{__callee__}", message: "#{path} does not exist"))
      end
    end
  end
end
