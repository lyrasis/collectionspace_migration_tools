# frozen_string_literal: true

require 'csv'
require 'dry/monads'

module CollectionspaceMigrationTools
  module Batch
    class Csv
      include Dry::Monads[:result]

      class DuplicateBatchIdError < CMT::Error; end

      attr_reader :ids
        
      def initialize(data = File.read(CMT.config.client.batch_csv)) 
        @table = CSV.parse(data, headers: true)
        @ids = table.by_col['id']
        ensure_id_uniqueness
      end

      def find_batch(bid)
        result = table.select{ |row| row['id'] == bid }
        return Failure("No batch with id: #{bid}") if result.empty?

        Success(result[0])
      end
      
      private

      attr_reader :table

      def ensure_id_uniqueness
        uniq_ids = ids.uniq
        return if ids == uniq_ids

        raise DuplicateBatchIdError
      end
    end
  end
end
