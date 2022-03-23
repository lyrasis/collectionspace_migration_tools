# frozen_string_literal: true

require 'collectionspace/client'
require 'dry/monads'

module CollectionspaceMigrationTools
  module RecordMapper
    # Returns CS Services API path for record type
    class ServicesPathGetter
      include CMT::RecordMapper::Extensions
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
      end

      def call
        service.bind do |service_hash|
          Success("/#{service_hash[:path]}")
        end
      end
      
      private
      
      attr_reader :mapper

      def authority_service
        result = CollectionSpace::Service.get(
          type: rec_type,
          subtype: rec_subtype
        )
      rescue StandardError => err
        Failure(CMT::Failure.new(context: "#{self.class.name}.#{__callee__}", message: err))
      else
        Success(result)
      end

      def normal_service
        result = CollectionSpace::Service.get(
          type: rec_service_path
        )
      rescue StandardError => err
        Failure(CMT::Failure.new(context: "#{self.class.name}.#{__callee__}", message: err))
      else
        Success(result)
      end
      
      def service
        return authority_service if authority?

        normal_service
      end
    end
  end
end

