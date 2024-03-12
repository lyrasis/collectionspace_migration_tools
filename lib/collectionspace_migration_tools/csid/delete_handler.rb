# frozen_string_literal: true

module CollectionspaceMigrationTools
  module Csid
    class DeleteHandler
      include Dry::Monads[:result]
      include Dry::Monads::Do.for(:call)

      class << self
        def call(...)
          new(...).call
        end
      end

      # @param csv_path [nil, String] path to CSV having `:rectype` and `:csid`
      #   fields
      def initialize(csv_path: nil)
        @csv_path = csv_path
      end

      def call
        puts "Setting up to batch delete by CSID..."

        client = yield CMT::Client.call
        deleter = yield CMT::Csid::Deleter.new(client: client)

        in_path = CMT.get_csv_path(csv_path)
        row_getter = yield CMT::Csv::FirstRowGetter.new(in_path)
        csvchecker = yield CMT::Csv::FileChecker.call(in_path, row_getter)
        first_row = csvchecker[1]

        processed = yield CMT::Csid::DeleteProcessor.call(
          deleter: deleter,
          csv_path: in_path
        )

        headers = processed.first.headers

        out_path = in_path.sub(".csv", "_report.csv")
        _written = yield write_report(
          path: out_path,
          headers: headers,
          rows: processed.map(&:to_h)
        )

        Success()
      end

      private

      attr_reader :csv_path, :derivable_image_types

      def write_report(path:, headers:, rows:)
        CSV.open(path, "w") do |csv|
          csv << headers
          rows.each { |row| csv << row.values_at(*headers) }
        end
      rescue => err
        msg = "#{err.message} IN #{err.backtrace[0]}"
        Failure(CMT::Failure.new(
          context: "#{self.class.name}.#{__callee__}", message: msg
        ))
      else
        puts "Wrote CSID delete report to #{path}..."
        Success()
      end
    end
  end
end
