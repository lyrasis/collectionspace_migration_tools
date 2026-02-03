# frozen_string_literal: true

require "dry/monads"
require "dry/monads/do"

module CollectionspaceMigrationTools
  module Xml
    # Handles writing XML files
    class FileWriter
      include Dry::Monads[:result]
      include Dry::Monads::Do.for(:write)

      def initialize(output_dir:, action_checker:, namer:, s3_key_creator:,
        reporter:)
        @output_dir = output_dir
        @action_checker = action_checker
        @namer = namer
        @s3_key_creator = s3_key_creator
        @reporter = reporter
      end

      # @param response [CollectionSpace::Mapper::Response]
      def call(response)
        write(response).either(
          ->(result) { reporter.report_success(result) },
          ->(result) { reporter.report_failure(result, self) }
        )
      end

      def to_monad
        Success(self)
      end

      private

      attr_reader :output_dir, :action_checker, :namer, :s3_key_creator,
        :reporter

      def add_key_warnings(key, response)
        key.warnings.each do |warning|
          response.add_warning({message: warning})
        end
      end

      def check_existence(name, path, response)
        if File.exist?(path) && exists_case_sensitively?(name)
          return Failure([:file_already_exists, response, name])
        end

        if File.exist?(path)
          name = name.sub(".xml", "_#{response.object_id}.xml")
        end

        Success(name)
      end

      # Mac OS will say the file exists if it is a case insensitive match. If
      #  the file does not exist with a case sensitive match, it is not really
      #  a duplicate.
      def exists_case_sensitively?(name)
        Dir.new(output_dir)
          .children
          .include?(name)
      end

      def write(response)
        action = yield action_checker.call(response)
        file_name = yield namer.call(response)
        path = "#{output_dir}/#{file_name}"
        key = yield s3_key_creator.call(response, action)

        add_key_warnings(key, response) unless key.warnings.empty?

        checkedname = yield check_existence(file_name, path, response)
        checkedpath = "#{output_dir}/#{checkedname}"
        _written = yield write_file(checkedpath, response)

        Success([response, checkedname, key.value])
      end

      def write_file(path, response)
        File.open(path, "wb") { |file| file << response.doc }
      rescue => err
        Failure([:error_on_write, response, err])
      else
        File.exist?(path) ? Success(response) : Failure([:file_not_written,
          response])
      end
    end
  end
end
