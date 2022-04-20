# frozen_string_literal: true

require 'csv'

module CollectionspaceMigrationTools
  module Batch
    module Csv
      class DoneMarker
        include Dry::Monads[:result]
        include Dry::Monads::Do.for(:call)

        class << self
          def call(...)
            self.new(...).call
          end
        end
        
        def initialize(
          csv: CMT::Batch::Csv::Reader.new,
          rewriter: CMT::Batch::Csv::Rewriter.new
        )
          @csv = csv
          @table = csv.table
          @rewriter = rewriter
        end

        def call
          marked_done = yield(update_table)
          _rewritten = yield(rewriter.call(table))

          Success(marked_done)
        end
        
        private

        attr_reader :csv, :table, :rewriter

        def check_row(row)
        end
        
        def update_table
          done_ids = []
          
          table.map{ |row| [row, CMT::Batch::Batch.new(csv, row['id'])] }
            .select{ |data| data[1].is_done? }
            .map{ |data| data[0] }
            .each do |row|
              next if row['done?'] == 'y'
              
              row['done?'] = 'y'
              done_ids << row['id']
            end
        rescue StandardError => err
          msg = "#{err.message} IN #{err.backtrace[0]}"
          Failure(CMT::Failure.new(context: "#{self.class.name}.#{__callee__}", message: msg))
        else
          Success(done_ids)
        end
      end
    end
  end
end
