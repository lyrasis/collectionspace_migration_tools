# frozen_string_literal: true

require "csv"

module CollectionspaceMigrationTools
  module Media
    ::CMT::Media = CollectionspaceMigrationTools::Media
    extend Dry::Monads[:result, :do]

    module_function

    def blob_data
      query = CMT::Database::Query.blobs_on_media
      puts "\nQuerying for media blob details..."
      rows = yield(CMT::Database::ExecuteQuery.call(query))
      CMT.connection&.close
      CMT.tunnel&.close

      Success(rows)
    end

    def blob_data_path
      result = File.join(
        CMT.config.client.base_dir,
        "blob_data.csv"
      )

      Success(result)
    rescue => err
      Failure(err.message)
    end

    def blob_data_report
      rows = yield blob_data
      path = yield blob_data_path
      _written = yield write_blob_data_report(rows, path)

      Success()
    end

    def write_blob_data_report(rows, path)
      headers = rows[0].keys
      CSV.open(path, "w") do |csv|
        csv << headers
        rows.each { |row| csv << row.values }
      end

      puts "Wrote blob data report to #{path}..."
      Success()
    rescue => err
      Failure(err.message)
    end
  end
end
