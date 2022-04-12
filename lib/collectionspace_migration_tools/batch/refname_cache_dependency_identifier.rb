# frozen_string_literal: true

require 'csv'
require 'dry/monads'
require 'dry/monads/do'

module CollectionspaceMigrationTools
  module Batch
    class RefnameCacheDependencyIdentifier
      include Dry::Monads[:result]
      include Dry::Monads::Do.for()
      
      class << self
        def call(...)
          self.new(...).call
        end
      end
      
      def initialize(headers:, mapper:)
        @headers = headers.map(&:downcase)
        @mappings = mapper.refname_columns
      end

      def call
        return Success('') if mappings.empty?
        
        res = mappings.select{ |mapping| headers.any?(mapping['datacolumn'].downcase) }
          .map{ |mapping| extract_cacheable(mapping) }
          .uniq
          .join('|')

        Success(res)
      end

      private

      attr_reader :headers, :mappings

      def extract_cacheable(mapping)
        return 'vocabulary' if mapping['source_type'] == 'vocabulary'

        mapping['source_name']
      end
    end
  end
end
