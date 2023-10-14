# frozen_string_literal: true

require "csv"
require "fileutils"

module CollectionspaceMigrationTools
  module Entity
    # mixin module adding deletion of all records by rectype to entity classes
    #
    # Classes mixing this in need to have the following methods:
    #   - all_csids_query
    #   - name
    module DeleteAllable
      include Dry::Monads[:result]
      include Dry::Monads::Do.for(:do_deletes)

      def delete_all
        do_deletes.either(
          ->(success) {
            FileUtils.rm(tmp_csv_path)
            puts "All #{success} #{name} records deleted."
            Success(success)
          },
          ->(failure) { Failure(failure) }
        )
      end

      def tmp_csv_path
        File.join(CMT.config.client.base_dir, "tmp_#{name}_delete.csv")
      end
      private :tmp_csv_path

      def do_deletes
        _status = yield self
        query = yield all_csids_query

        puts "\nQuerying for #{name} CSIDs to delete..."
        rows = yield CMT::Database::ExecuteQuery.call(query)
        count = rows.count
        _proceed = yield any_to_delete(count)
        _written = yield csv_writer(rows)

        puts "\nDeleting #{count} #{name} records..."
        yield CMT::Csid::DeleteHandler.call(csv_path: tmp_csv_path)

        Success(count)
      end
      private :do_deletes

      def any_to_delete(count)
        return Failure("No #{name} records to delete") if count == 0

        Success()
      end

      def csv_writer(rows)
        headers = %w[csid rectype]
        CSV.open(tmp_csv_path, "w") do |csv|
          csv << headers
          rows.each { |row| csv << row.values_at(*headers) }
        end
      rescue => err
        Failure(CMT::Failure.new(
          context: "#{name}.#{__callee__}",
          message: err.message
        ))
      else
        Success()
      end
      private :csv_writer
    end
  end
end
