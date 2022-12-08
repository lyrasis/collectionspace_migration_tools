# frozen_string_literal: true

require 'csv'

module CollectionspaceMigrationTools
  module Media
    ::CMT::Media = CollectionspaceMigrationTools::Media
    extend Dry::Monads[:result, :do]

    module_function

    def blob_data
      query = CMT::Database::Query.blobs_on_media
      puts "\nQuerying for media blob details..."
      rows = yield(CMT::Database::ExecuteQuery.call(query))
      CMT.connection.close if CMT.connection
      CMT.tunnel.close if CMT.tunnel

      Success(rows)
    end

    def blob_data_path
      result = File.join(
        CMT.config.client.base_dir,
        'blob_data.csv'
      )
    rescue StandardError => err
      msg = "#{err.message} IN #{err.backtrace[0]}"
      Failure(CMT::Failure.new(
        context: "#{self.name}.#{__callee__}(#{key})", message: msg
      ))
    else
      Success(result)
    end

    def blob_data_report
      rows = yield blob_data
      path = yield blob_data_path
      _written = yield write_blob_data_report(rows, path)

      Success()
    end

    def write_blob_data_report(rows, path)
      headers = rows[0].keys
      CSV.open(path, 'w') do |csv|
        csv << headers
        rows.each{ |row| csv << row.values }
      end
    rescue StandardError => err
      msg = "#{err.message} IN #{err.backtrace[0]}"
      Failure(CMT::Failure.new(
        context: "#{self.name}.#{__callee__}(#{key})", message: msg
      ))
    else
      puts "Wrote blob data report to #{path}..."
      Success()
    end
  end
end
