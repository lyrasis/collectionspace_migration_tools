# frozen_string_literal: true

require "collectionspace/mapper"
require "dry/monads"
require "json"

module CollectionspaceMigrationTools
  module Build
    # Returns CollectionSpace::Mapper::DataHandler
    class DataHandler
      include Dry::Monads[:result]

      class << self
        def call(record_mapper, batch_config)
          new(record_mapper, batch_config).call
        end
      end

      def initialize(record_mapper, batch_config)
        @record_mapper = record_mapper
        @batch_config = batch_config
      end

      def call
        result = CollectionSpace::Mapper::DataHandler.new(
          record_mapper: record_mapper.to_h,
          client: CMT.client,
          cache: CMT.refname_cache,
          csid_cache: CMT.csid_cache,
          config: batch_config
        )

        Success(result)
      rescue CollectionSpace::Mapper::NoClientServiceError => err
        Failure("collectionspace-client does not have a service configured "\
          "for #{err.message}")
      rescue CollectionSpace::Mapper::IdFieldNotInMapperError
        Failure("Cannot determine the unique ID field for this record type. "\
          "RecordMapper needs correction")
      rescue => err
        Failure(err.message)
      end

      private

      attr_reader :record_mapper, :batch_config
    end
  end
end
