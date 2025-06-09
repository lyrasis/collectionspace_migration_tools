# frozen_string_literal: true

require "csv"

module CollectionspaceMigrationTools
  module RefnameReport
    ::CMT::RefnameReport = CollectionspaceMigrationTools::RefnameReport
    extend Dry::Monads[:result, :do]

    module_function

    # @param rectypes [Array<#cacheable_data_query>]
    def write(rectypes)
      data = yield refname_data(rectypes)
      path = yield refname_data_path
      _written = yield write_blob_data_report(data, path)

      Success()
    end

    # @param rectypes [Array<#cacheable_data_query>]
    def refname_data(rectypes)
      data = rectypes.map do |rectype|
        query = yield rectype.cacheable_data_query
        puts "\nQuerying for #{rectype.name} refnames..."
        rows = yield CMT::Database::ExecuteQuery.call(query)
        rows.to_a
      end

      Success(data.flatten)
    end

    def refname_data_path
      result = File.join(
        CMT.config.client.base_dir,
        "refname_data.csv"
      )
    rescue => err
      msg = "#{err.message} IN #{err.backtrace[0]}"
      Failure(CMT::Failure.new(
        context: "#{name}.#{__callee__}(#{key})", message: msg
      ))
    else
      Success(result)
    end

    def write_blob_data_report(rows, path)
      headers = rows[0].keys
      CSV.open(path, "w") do |csv|
        csv << headers
        rows.each { |row| csv << row.values }
      end
    rescue => err
      msg = "#{err.message} IN #{err.backtrace[0]}"
      Failure(CMT::Failure.new(
        context: "#{name}.#{__callee__}(#{key})", message: msg
      ))
    else
      puts "Wrote refname data report to #{path}..."
      Success()
    end
  end
end
