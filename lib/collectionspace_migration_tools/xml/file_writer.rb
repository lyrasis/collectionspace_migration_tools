# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module CollectionspaceMigrationTools
  module Xml
    # Handles writing XML files
    class FileWriter
      include Dry::Monads[:result]
      include Dry::Monads::Do.for(:write)

      def initialize(output_dir:, namer:, reporter:)
        puts "Setting up #{self.class.name}..."
        @output_dir = output_dir
        @namer = namer
        @reporter = reporter
      end

      # @param response [CollectionSpace::Mapper::Response]
      def call(response)
        write(response).either(
          ->(result){ reporter.report_success(result) },
          ->(result){ reporter.report_failure(result, self) }
        )
      end

      def to_monad
        Success(self)
      end
      
      private

      attr_reader :output_dir, :namer, :reporter

      def check_existence(path, response)
        return Failure([:file_already_exists, response]) if File.exist?(path)
        
        Success(response)
      end
      
      def get_file_name(response)
        result = namer.call(response.identifier)
      rescue StandardError => err
        Failure(CMT::Failure.new(context: "#{self.class.name}.#{__callee__}", message: err))
      else
        Success(result)
      end

      def write(response)
        file_name = yield(get_file_name(response))
        path = "#{output_dir}/#{file_name}"
        _checked = yield(check_existence(path, response))
        _written = yield(write_file(path, response))

        Success(response)
      end
      
      def write_file(path, response)
        File.open(path, 'wb'){ |file| file << response.doc }
      rescue StandardError => err
        Failure([:error_on_write, response, err.message])
      else
       File.exist?(path) ? Success(response) : Failure([:file_not_written, response])
      end
    end
  end
end
