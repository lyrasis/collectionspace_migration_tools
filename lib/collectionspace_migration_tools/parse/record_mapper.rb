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

        Success(hash)
      rescue => err
        Failure(err.message)
      end

      def mapper_path
        filename = "#{CMT.config.client.profile}_"\
          "#{CMT.config.client.profile_version}_#{rectype}.json"
        File.join(CMT.config.client.mapper_dir, filename)
      end

      def parse(json)
        result = JSON.parse(json)

        Success(result)
      rescue => err
        Failure(err.message)
      end

      def read_json
        result = File.read(mapper_path)

        Success(result)
      rescue => err
        Failure(err.message)
      end

      def validate_rectype
        return Success(rectype) if CMT::RecordTypes.mappable.any?(rectype)

        Failure("No record mapper for #{rectype} in "\
          "#{CMT.config.client.mapper_dir}")
      end
    end
  end
end
