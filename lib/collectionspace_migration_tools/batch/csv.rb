# frozen_string_literal: true

require 'csv'
require 'dry/monads'

module CollectionspaceMigrationTools
  module Batch
    class Csv
      include Dry::Monads[:result]

      class DuplicateBatchIdError < CMT::Error; end

      attr_reader :ids
        
      def initialize(data = File.read(CMT.config.client.batch_csv), rewriter = CMT::Batch::CsvRewriter.new) 
        @table = CSV.parse(data, headers: true)
        @rewriter = rewriter
        @ids = table.by_col['id']
      end

      def find_batch(bid)
        result = table.select{ |row| row['id'] == bid }
        return Failure("No batch with id: #{bid}") if result.empty?

        Success(result[0])
      end

      def list
        table.each do |row|
          info = [
            row['id'],
            row['action'],
            row['rec_ct'],
            row['mappable_rectype'],
            File.basename(row['source_csv'])
          ]
          puts info.join("\t")
        end
      end
      
      def to_monad
        ensure_id_uniqueness
      rescue DuplicateBatchIdError => err
        Failure('Batch ids are not unique. Please manually edit and save CSV where info about batches is recorded.')
      else
        Success(self)
      end

      def rewrite
        rewriter.call(table)
      end
      
      private

      attr_reader :table, :rewriter

      def ensure_id_uniqueness
        uniq_ids = ids.uniq
        return if ids == uniq_ids

        raise DuplicateBatchIdError
      end
    end
  end
end
