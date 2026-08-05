# frozen_string_literal: true

require "dry/monads"
require "dry/monads/do"
require "json"

module CollectionspaceMigrationTools
  module Parse
    # Parses client batch config if present. Starts with empty config if none
    #   given.
    # Merges required `status_check_method` and `search_if_not_cached` values.
    class BatchConfig
      include Dry::Monads[:result]
      include Dry::Monads::Do.for(:call)

      class << self
        def call
          new.call
        end
      end

      def initialize
        @path = get_path
      end

      def call
        string = yield(read)
        hash = yield(parse(string))

        Success(hash.merge({"status_check_method" => "cache",
"search_if_not_cached" => false}))
      end

      private

      attr_reader :path

      def get_path
        CMT.config.client.batch_config_path
      rescue
        nil
      end

      def parse(str)
        result = JSON.parse(str)

        Success(result)
      rescue => err
        Failure(err.message)
      end

      def read
        return Success("{}") if path.nil?

        unless File.exist?(path)
          return Failure("Batch config file does not exist at #{path}")
        end

        result = File.read(path)

        Success(result)
      rescue => err
        Failure(err.message)
      end
    end
  end
end
