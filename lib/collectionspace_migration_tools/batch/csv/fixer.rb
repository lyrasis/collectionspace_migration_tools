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

        def add_missing_headers(hdrs)
          new_table = CSV::Table.new([], headers: all_headers)
          data = table.values_at(*all_headers)
          mapped = data.map{ |rowdata| CSV::Row.new(all_headers, rowdata)}
          mapped.each{ |row| new_table << row }
          @table = new_table
        rescue StandardError => err
          msg = "#{err.message} IN #{err.backtrace[0]}"
          Failure(CMT::Failure.new(context: "#{self.class.name}.#{__callee__}", message: msg))
        else
          Success("Added missing headers: #{hdrs.join(', ')}")
        end
        
        def check_extra_headers
          extra = table.headers - all_headers
          return if extra.empty?

          @to_do << [:remove_extra_headers, extra]
        end

        def check_missing_headers
          missing = all_headers - table.headers
          return if missing.empty?

          @to_do << [:add_missing_headers, missing]
        end

        def generate_failure(failure)
          return Failure(failure) if tracker.empty?

          msg = "#{tracker.join(';')} BUT THEN FAILED: #{failure.to_s}"
          Failure(msg)
        end
        
        def generate_to_do_list
          header_tasks if check_headers.failure?
        rescue StandardError => err
          msg = "#{err.message} IN #{err.backtrace[0]}"
          Failure(CMT::Failure.new(context: "#{self.class.name}.#{__callee__}", message: msg))
        else
          Success()
        end

        def handle_to_dos
          if to_do.empty?
            @status = Success('Nothing to fix!')
            return status
          end

          to_do.each do |task|
            meth = task.shift
            self.send(meth, *task).either(
              ->(ok_msg){ tracker << ok_msg },
              ->(failure){ @status = generate_failure(failure) }
            )
            break status if status && status.failure?
          end

          @status = Success(tracker.join(';'))
          status
        end
        
        def header_tasks
          check_extra_headers
          check_missing_headers
        end

        def remove_extra_headers(hdrs)
          hdrs.each{ |hdr| table.delete(hdr) }
        rescue StandardError => err
          msg = "#{err.message} IN #{err.backtrace[0]}"
          Failure(CMT::Failure.new(context: "#{self.class.name}.#{__callee__}", message: msg))
        else
          Success("Removed extra headers: #{hdrs.join(', ')}")
        end
      end
    end
  end
end
