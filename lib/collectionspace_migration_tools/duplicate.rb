# frozen_string_literal: true

module CollectionspaceMigrationTools
  module Duplicate
    # extend Dry::Monads[:result, :do]

    module_function

    def check_all_and_write_reports
      report_dir = File.join(CMT.config.client.base_dir, "duplicate_reports")
      FileUtils.mkdir_p(report_dir)

      results = {}
      CMT::RecordTypes.mappable
        .each do |rt|
          result = CMT::Duplicate::Checker.call(rectype: rt)
          results[rt] = result
          if result.failure?
            f = result.failure
            str = f.respond_to?(:message) ? f.message : f
            puts str
            next
          end

          duplicates = result.value!
          ct = duplicates.num_tuples
          puts "#{ct} #{rt} duplicates"
          next if ct == 0

          path = File.join(report_dir, "#{rt}.csv")
          CMT::Duplicate::CsvWriter.call(path: path, duplicates: duplicates)
          puts "Wrote output to #{path}"
        end
    end
  end
end
