# frozen_string_literal: true

require 'collectionspace/client'
require 'dry/monads'

module CollectionspaceMigrationTools
  module Xml
    # Returns CS Services API path for record type
    class ServicesApiPathGetter
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
        puts "Setting up #{self.class.name}..."
        service.bind do |service_hash|
          Success("/#{service_hash[:path]}")
        end
      end
      
      private
      
      attr_reader :mapper

      def authority_service
        result = CollectionSpace::Service.get(
          type: mapper.type,
          subtype: mapper.subtype
        )
      rescue StandardError => err
        Failure(CMT::Failure.new(context: "#{self.class.name}.#{__callee__}", message: err))
      else
        Success(result)
      end

      def normal_service
        result = CollectionSpace::Service.get(
          type: mapper.service_path
        )
      rescue StandardError => err
        Failure(CMT::Failure.new(context: "#{self.class.name}.#{__callee__}", message: err))
      else
        Success(result)
      end
      
      def service
        return authority_service if mapper.authority?

        normal_service
      end
    end
  end
end

