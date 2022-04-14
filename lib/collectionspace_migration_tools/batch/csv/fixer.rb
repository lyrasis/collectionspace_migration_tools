# frozen_string_literal: true

require 'csv'

module CollectionspaceMigrationTools
  module Batch
    module Csv
      class Fixer
        include CMT::Batch::Csv::Headers
        include Dry::Monads[:result]
        include Dry::Monads::Do.for(:call)

        class << self
          def call(...)
            self.new(...).call
          end
        end
        
        def initialize(
          data = File.read(CMT.config.client.batch_csv),
          rewriter = CMT::Batch::Csv::Rewriter.new
        ) 
          @table = CSV.parse(data, headers: true)
          @rewriter = rewriter
          @to_do = []
          @tracker = []
        end

        def call
          _list = yield(generate_to_do_list)
          _handled = yield(handle_to_dos)
          _written = yield(rewriter.call(table))

          Success(status.value!)
        end
        
        def to_monad
          status
        end
        
        #        private

        attr_reader :table, :rewriter, :to_do, :status, :tracker

        def update_csv_columns
          new_table = CSV::Table.new([], headers: all_headers)
          data = table.values_at(*all_headers)
          mapped = data.map{ |rowdata| CSV::Row.new(all_headers, rowdata)}
          mapped.each{ |row| new_table << row }
          @table = new_table
        rescue StandardError => err
          msg = "#{err.message} IN #{err.backtrace[0]}"
          Failure(CMT::Failure.new(context: "#{self.class.name}.#{__callee__}", message: msg))
        else
          Success("Updated CSV columns")
        end

        def generate_to_do_list
          update_csv_columns if check_headers.failure?
        rescue StandardError => err
          msg = "#{err.message} IN #{err.backtrace[0]}"
          Failure(CMT::Failure.new(context: "#{self.class.name}.#{__callee__}", message: msg))
        else
          Success()
        end

        
      end
    end
  end
end
