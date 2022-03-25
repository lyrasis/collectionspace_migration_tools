# frozen_string_literal: true

require 'collectionspace/mapper'
require 'dry/monads'
require 'json'

module CollectionspaceMigrationTools
  module Build
  # Returns CollectionSpace::Mapper::DataHandler
    class DataHandler
      include Dry::Monads[:result]

      class << self
        def call(record_mapper, batch_config)
          self.new(record_mapper, batch_config).call
        end
      end

      def initialize(record_mapper, batch_config)
        @record_mapper = record_mapper
        @batch_config = batch_config
      end

      def call
        puts "Setting up #{self.class.name}..."
        result = CollectionSpace::Mapper::DataHandler.new(
          record_mapper: record_mapper.to_h,
          client: CMT.client,
          cache: CMT.refname_cache,
          csid_cache: CMT.csid_cache,
          config: batch_config
        )
      rescue CollectionSpace::Mapper::NoClientServiceError => err
        msg = "collectionspace-client does not have a service configured for #{err.message}"
        Failure(CMT::Failure.new(context: "#{self.class.name}.#{__callee__}", message: msg))
      rescue CollectionSpace::Mapper::DataValidator::IdFieldNotInMapperError => err
        msg = "Cannot determine the unique ID field for this record type. RecordMapper needs correction"
        Failure(CMT::Failure.new(context: "#{self.class.name}.#{__callee__}", message: msg))
      rescue StandardError => err
        Failure(CMT::Failure.new(context: "#{self.class.name}.#{__callee__}", message: err))
      else
        Success(result)
      end
      
      private

      attr_reader :record_mapper, :batch_config
    end
  end
end
