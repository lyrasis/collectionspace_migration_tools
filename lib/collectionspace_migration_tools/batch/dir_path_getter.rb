# frozen_string_literal: true

require "fileutils"

module CollectionspaceMigrationTools
  module Batch
    # Returns directory path for batch and creates directory if it does not exist
    class DirPathGetter
      include Dry::Monads[:result]

      class << self
        # @param record_mapper [Hash] parsed JSON record mapper
        def call(...)
          new(...).call
        end
      end

      # @param record_mapper [Hash] parsed JSON record mapper
      def initialize(mapper, batch = nil)
        @mapper = mapper
        @batch = batch
        @batch_dir = File.expand_path(CMT.config.client.batch_dir)
      end

      def call
        construct_path.bind do
          ensure_dir
        end
      end

      private

      attr_reader :mapper, :batch, :batch_dir, :path

      def construct_path
        result = if batch
          "#{batch_dir}/#{batch}_#{timestamp}"
        else
          "#{batch_dir}/#{timestamp}_#{mapper.type_subtype}"
        end
      rescue => err
        Failure(CMT::Failure.new(context: "#{self.class.name}.#{__callee__}",
          message: err))
      else
        @path = result
        Success(result)
      end

      def create_dir
        FileUtils.mkdir_p(path)
      rescue => err
        Failure(CMT::Failure.new(context: "#{self.class.name}.#{__callee__}",
          message: err))
      else
        Success(path)
      end

      def ensure_dir
        return Success(path) if Dir.exist?(path)

        create_dir
      end

      def timestamp
        now = Time.now
        now.strftime("%F_%H_%M")
      end
    end
  end
end
