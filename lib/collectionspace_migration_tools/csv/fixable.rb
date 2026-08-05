# frozen_string_literal: true

module CollectionspaceMigrationTools
  module Csv
    # Mixin module for shared behavior to fix CSV data files
    module Fixable
      extend Dry::Monads[:result, :do]

      def update_csv_columns(table, headers)
        new_table = CSV::Table.new([], headers: headers)
        data = table.values_at(*headers)
        mapped = data.map { |rowdata| CSV::Row.new(headers, rowdata) }
        mapped.each { |row| new_table << row }

        Success(new_table)
      rescue => err
        Failure(err.message)
      end
    end
  end
end
