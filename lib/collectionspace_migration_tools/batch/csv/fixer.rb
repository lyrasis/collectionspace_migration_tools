# frozen_string_literal: true

require "csv"

module CollectionspaceMigrationTools
  module Batch
    module Csv
      class Fixer
        include CMT::Csv::Fixable
        include Dry::Monads[:result]
        include Dry::Monads::Do.for(:call)

        class << self
          def call(...)
            new(...).call
          end
        end

        def initialize(
          data: File.read(CMT.config.client.batch_csv),
          rewriter: CMT::Batch::Csv::Rewriter.new,
          headers: CMT::Batch::Csv::Headers.all_headers,
          derived_headers: CMT::Batch::Csv::Headers.derived_headers
        )
          @table = CSV.parse(data, headers: true)
          @rewriter = rewriter
          @headers = headers
          @derived_headers = derived_headers
        end

        def call
          todos = yield(compile_to_fix)
          return Success("Nothing to fix!") if todos.empty?

          fixed = yield(do_fixes(todos))
          _written = yield(rewriter.call(table))

          Success(fixed.map(&:value!).join("; "))
        end

        private

        attr_reader :table, :rewriter, :headers, :derived_headers

        def check_headers
          return Success() if table.headers == headers

          Failure([:update_csv_columns])
        end

        def compile_to_fix
          to_do = [check_headers, derived_populated].select do |chk|
            chk.failure?
          end
        rescue => err
          msg = "#{err.message} IN #{err.backtrace[0]}"
          Failure(CMT::Failure.new(context: "#{self.class.name}.#{__callee__}",
            message: msg))
        else
          Success(to_do)
        end

        def derive_rec_ct(rows)
          cts = rows.map do |row|
            CMT::Batch::CsvRowCounter.call(path: row["source_csv"])
          end
          if cts.any?(&:failure)
            failed_ids = []
            cts.each_with_index do |result, idx|
              next if result.success?

              failed_ids << rows[idx]["id"]
            end
            Failure("rec_ct could not be derived for: #{failed_ids.join(", ")}")
          else
            rows.each_with_index { |row, idx| row["rec_ct"] = cts[idx].value! }
            Success("Derived values provided for rec_ct")
          end
        end

        def derived_columns_missing_values
          need_population = []
          derived_headers.each do |hdr|
            vals = table.values_at(hdr)
              .flatten
              .select { |val| val.nil? || val.empty? }
            need_population << hdr unless vals.empty?
          end
          need_population
        end

        def derived_populated
          fix_cols = derived_columns_missing_values
          return Success() if fix_cols.empty?

          Failure([:populate_derived, fix_cols])
        end

        def call_fix(meth, task)
          if meth == :update_csv_columns
            fixed = update_csv_columns(table, headers)
            if fixed.success?
              @table = fixed.value!
              Success("Updated CSV columns")
            else
              fixed
            end
          else
            task.empty? ? send(meth) : send(meth, *task)
          end
        end

        def do_fixes(todos)
          results = todos.map do |todo|
            task = todo.failure
            meth = task.shift
            call_fix(meth, task)
          end

          if results.any?(&:failure?)
            Failure(results.select(&:failure?).map(&:failure).join("; "))
          else
            Success(results)
          end
        end

        def populate_derived(cols)
          results = cols.map do |col|
            send("derive_#{col}".to_sym, rows_needing_population(col))
          end

          if results.any?(&:failure?)
            Failure(results.select(&:failure?).map(&:failure).join("; "))
          else
            Success("Populated missing derived data")

          end
        end

        def rows_needing_population(col)
          table.select { |row| row[col].nil? || row[col].empty? }
        end
      end
    end
  end
end
