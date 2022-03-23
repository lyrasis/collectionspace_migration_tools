# frozen_string_literal: true

require 'dry/monads'
require 'json'

module CollectionspaceMigrationTools
  module Parse
    # Parses the JSON record mapper for the given record type
    class RecordMapper
      include Dry::Monads[:result]
      class << self

        def call(rectype)
          self.new(rectype).call
        end
      end

      def initialize(rectype)
        @rectype = rectype
      end

      def call
        validate_rectype.bind do
          read_json.bind do |json|
            parse(json) do |hash|
              Success(CMT::RecordMapper.new(hash))
            end
          end
        end
      end
      
      private

      attr_reader :rectype

      def mapper_path
        filename = "#{CMT.config.client.profile}_#{CMT.config.client.profile_version}_#{rectype}.json"
        File.join(CMT.config.client.mapper_dir, filename)
      end

      def parse(json)
        result = JSON.parse(json)
      rescue StandardError => err
        Failure(CMT::Failure.new(context: "#{self.class.name}.#{__callee__}", message: err))
      else
        Success(result)
      end

      def read_json
        result = File.read(mapper_path)
      rescue StandardError => err
        Failure(CMT::Failure.new(context: "#{self.class.name}.#{__callee__}", message: err))
      else
        Success(result)
      end
      
      def validate_rectype
        return Success(rectype) if CMT::RecordTypes.mappable.any?(rectype)

        msg = "No record mapper for #{rectype} in #{CMT.config.client.mapper_dir}"
        Failure(CMT::Failure.new(context: "#{self.class.name}.#{__callee__}", message: msg))
      end

    end
  end
end
