# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'
require 'json'

module CollectionspaceMigrationTools
  module Parse
    # Parses client batch config if present
    class BatchConfig
      include Dry::Monads[:result]
      include Dry::Monads::Do.for(:call)
      
      class << self
        def call
          self.new.call
        end
      end

      def initialize
        @path = get_path
      end

      def call
        string = yield(read)
        hash = yield(parse(string))

        Success(hash.merge({'status_check_method' => 'cache', 'search_if_not_cached' => false}))
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
      rescue StandardError => err
        Failure(CMT::Failure.new(context: "#{self.class.name}.#{__callee__}", message: err))
      else
        Success(result)
      end
      
      def read
        return Success("{}") if path.nil?

        unless File.exist?(path)
          msg = "Batch config file does not exist at #{path}"
          return Failure(CMT::Failure.new(context: "#{self.class.name}.#{__callee__}", message: msg))
        end
        
        result = File.read(path)
      rescue StandardError => err
        Failure(CMT::Failure.new(context: "#{self.class.name}.#{__callee__}", message: err))
      else
        Success(result)
      end
    end
  end
end

