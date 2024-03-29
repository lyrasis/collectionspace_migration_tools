# frozen_string_literal: true

require "dry/monads"
require "dry/monads/do"
require "json"

module CollectionspaceMigrationTools
  module Parse
    # Parses the JSON record mapper for the given record type
    class RecordMapper
      include Dry::Monads[:result]
      include Dry::Monads::Do.for(:call)

      class << self
        def call(rectype)
          new(rectype).call
        end
      end

      def initialize(rectype)
        @rectype = rectype
      end

      def call
        _rec_type = yield(validate_rectype)
        json = yield(read_json)
        hash = yield(parse(json))
        named = yield(insert_name(hash))
        mapper = yield(CMT::RecordMapper.new(named))

        Success(mapper)
      end

      private

      attr_reader :rectype

      def insert_name(hash)
        hash["config"]["mapper_name"] = rectype
      rescue => err
        Failure(CMT::Failure.new(context: "#{self.class.name}.#{__callee__}",
          message: err))
      else
        Success(hash)
      end

      def mapper_path
        filename = "#{CMT.config.client.profile}_#{CMT.config.client.profile_version}_#{rectype}.json"
        File.join(CMT.config.client.mapper_dir, filename)
      end

      def parse(json)
        result = JSON.parse(json)
      rescue => err
        Failure(CMT::Failure.new(context: "#{self.class.name}.#{__callee__}",
          message: err))
      else
        Success(result)
      end

      def read_json
        result = File.read(mapper_path)
      rescue => err
        Failure(CMT::Failure.new(context: "#{self.class.name}.#{__callee__}",
          message: err))
      else
        Success(result)
      end

      def validate_rectype
        return Success(rectype) if CMT::RecordTypes.mappable.any?(rectype)

        msg = "No record mapper for #{rectype} in #{CMT.config.client.mapper_dir}"
        Failure(CMT::Failure.new(context: "#{self.class.name}.#{__callee__}",
          message: msg))
      end
    end
  end
end
