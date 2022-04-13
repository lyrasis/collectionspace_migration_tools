# frozen_string_literal: true

require 'csv'

module CollectionspaceMigrationTools
  module Batch
    module Csv
      class Reader
        include Dry::Monads[:result]
        include Dry::Monads::Do.for(:do_delete)
        
        attr_reader :ids
        
        def initialize(data = File.read(CMT.config.client.batch_csv), rewriter = CMT::Batch::Csv::Rewriter.new) 
          @table = CSV.parse(data, headers: true)
          @rewriter = rewriter
          @ids = table.by_col['id']
        end

        def delete_batch(bid)
          return Failure("No batch with id: #{bid}. Cannot delete") unless ids.any?(bid)

          do_delete(bid)
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
          check_id_uniqueness
        end

        def rewrite
          rewriter.call(table)
        end
        
        private

        attr_reader :table, :rewriter

        def check_id_uniqueness
          uniq_ids = ids.uniq
          return Success(self) if ids == uniq_ids

          Failure('Batch ids are not unique. Please manually edit and save CSV where info about batches is recorded.')
        end

        def delete_from_table(bid)
          table.by_row!
          table.delete_if{ |row| row['id'] == bid }
        rescue StandardError => err
          msg = "#{err.message} IN #{err.backtrace[0]}"
          Failure(CMT::Failure.new(context: "#{self.class.name}.#{__callee__}", message: msg))
        else
          Success()
        end
        
        
        def do_delete(bid)
          _removed = yield(delete_from_table(bid))
          _rewritten = yield(rewrite)

          puts "Batch #{bid} deleted.\nRemaining batches:"
          list

          Success()
        end
      end
    end
  end
end
