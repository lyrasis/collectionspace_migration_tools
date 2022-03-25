# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module CollectionspaceMigrationTools
  module Xml
    # Handles writing XML files
    class FileWriter
      include Dry::Monads[:result]
      include Dry::Monads::Do.for(:call)

      def initialize(output_dir:, namer:)
        puts "Setting up #{self.class.name}..."
        @output_dir = output_dir
        @namer = namer
      end

      # @param response [CollectionSpace::Mapper::Response]
      def call(response)
        file_name = yield(get_file_name(response))
        _written = yield(write_file(file_name, response))

        Success()
      end

      def to_monad
        Success(self)
      end
      
      private

      attr_reader :output_dir, :namer

      def get_file_name(response)
        result = namer.call(response.identifier)
      rescue StandardError => err
        Failure(CMT::Failure.new(context: "#{self.class.name}.#{__callee__}", message: err))
      else
        Success(result)
      end

      def write_file(file_name, response)
        path = "#{output_dir}/#{file_name}"
        File.open(path, 'wb'){ |file| file << response.doc }
      rescue StandardError => err
        Failure(CMT::Failure.new(context: "#{self.class.name}.#{__callee__}", message: err))
      else
       File.exist?(path) ? Success(response) : Failure([:file_not_written, response])
      end
    end
  end
end
