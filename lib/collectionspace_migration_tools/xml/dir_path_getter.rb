# frozen_string_literal: true

require 'dry/monads'
require 'fileutils'

module CollectionspaceMigrationTools
  module Xml
    # Returns directory path for batch and creates directory if it does not exist
    class DirPathGetter
      include Dry::Monads[:result]

      class << self
        # @param record_mapper [Hash] parsed JSON record mapper
        def call(mapper)
          self.new(mapper).call
        end
      end

      # @param record_mapper [Hash] parsed JSON record mapper
      def initialize(mapper)
        @mapper = mapper
        @xml_dir = File.expand_path(CMT.config.client.xml_dir)
      end

      def call
        construct_path.bind do
          ensure_dir
        end
      end
      
      private

      attr_reader :mapper, :xml_dir, :path

      def construct_path
        result = "#{xml_dir}/#{timestamp}_#{mapper.type_subtype}"
      rescue StandardError => err
        Failure(CMT::Failure.new(context: "#{self.class.name}.#{__callee__}", message: err))
      else
        @path = result
        Success(result)
      end

      def create_dir
        FileUtils.mkdir_p(path)
      rescue StandardError => err
        Failure(CMT::Failure.new(context: "#{self.class.name}.#{__callee__}", message: err))
      else
        Success(path)
      end
      
      def ensure_dir
        return Success(path) if Dir.exist?(path)

        create_dir
      end

      def timestamp
        now = Time.now
        now.strftime("%F_%H:%M")
      end
    end
  end
end

