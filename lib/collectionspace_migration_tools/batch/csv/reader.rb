# frozen_string_literal: true

require "csv"
require "tabulo"

module CollectionspaceMigrationTools
  module Batch
    module Csv
      class Reader
        include Dry::Monads[:result]
        include Dry::Monads::Do.for(:do_delete, :to_monad, :get_data)

        attr_reader :ids, :table

        def initialize(
          data: nil,
          rewriter: CMT::Batch::Csv::Rewriter.new,
          headers: CMT::Batch::Csv::Headers.all_headers
        )
          data = get_data if data.nil?
          @table = CSV.parse(data, headers: true)
          @rewriter = rewriter
          @headers = headers
          @ids = table.by_col["id"]
        end

        def delete_batch(bid)
          return Failure("No batch with id: #{bid}. Cannot delete") unless ids.any?(bid)

          do_delete(bid)
        end

        def find_batch(bid)
          result = table.select { |row| row["id"] == bid }
          return Failure("No batch with id: #{bid}") if result.empty?

          Success(result[0])
        end

        # @param status [Symbol] eg. :mappable?, :uploadable?
        def find_status(status)
          result = table.delete_if { |row| !to_batch(row).send(status) }
          if result.empty?
            Failure("No #{status.to_s.delete_suffix("?")} batches")
          else
            Success(result)
          end
        end

        # @param data [#each] where each returns a CSV Row
        def to_cli_table(data = table)
          tt = Tabulo::Table.new(data.by_row, align_header: :left,
            align_body: :left)
          header_map.each do |real, cli|
            tt.add_column(cli) { |row| row[real] }
          end
          tt.add_column("source") { |row| File.basename(row["source_csv"]) }
          puts tt.pack
        end

        def list
          table.each do |row|
            puts %w[id status action recs rectype source].join("\t")
            puts printable_row(row)
          end
        end

        def printable_row(row)
          [
            row["id"],
            row["batch_status"],
            row["action"],
            row["rec_ct"],
            row["mappable_rectype"],
            File.basename(row["source_csv"])
          ].join("\t")
        end

        def rewrite
          rewriter.call(table)
        end

        def to_monad
          _hdrs = yield(header_check)
          _uniq = yield(check_id_uniqueness)

          Success(self)
        end

        private

        attr_reader :rewriter, :headers

        # Map actual CSV headers to headers for CLI table display
        def header_map
          {
            "id" => "id",
            "batch_status" => "status",
            "action" => "action",
            "rec_ct" => "recs",
            "mappable_rectype" => "rectype"
          }
        end

        def check_id_uniqueness
          uniq_ids = ids.uniq
          return Success(self) if ids == uniq_ids

          Failure("Batch ids are not unique. Please manually edit and save CSV where info about batches is recorded.")
        end

        def get_data
          read_batches_csv.either(
            ->(data) { data },
            ->(failure) {
              CMT::Batch::Csv::Creator.call
              read_batches_csv.value!
            }
          )
        end

        def to_batch(row)
          CMT::Batch::Batch.new(self, row["id"])
        end

        def delete_from_table(bid)
          table.by_row!
          table.delete_if { |row| row["id"] == bid }
        rescue => err
          msg = "#{err.message} IN #{err.backtrace[0]}"
          Failure(CMT::Failure.new(context: "#{self.class.name}.#{__callee__}",
            message: msg))
        else
          Success()
        end

        def header_check
          return Success() if table.headers == headers

          problem = "Batch CSV headers are not up-to-date, so batch workflows may fail unexpectedly."
          fix = "Run `thor batches:fix_csv` to fix"
          Failure("#{problem} #{fix}")
        end

        def do_delete(bid)
          _removed = yield(delete_from_table(bid))
          _rewritten = yield(rewrite)

          puts "Batch #{bid} deleted.\nRemaining batches:"
          list

          Success()
        end

        def read_batches_csv
          data = File.read(CMT.config.client.batch_csv)
        rescue => err
          msg = "#{err.message} IN #{err.backtrace[0]}"
          Failure(CMT::Failure.new(context: "#{self.class.name}.#{__callee__}",
            message: msg))
        else
          Success(data)
        end
      end
    end
  end
end
