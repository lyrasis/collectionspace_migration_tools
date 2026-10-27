# frozen_string_literal: true

require "fileutils"
require "thor"

# Tasks targeting batches archive CSV
class Archive < Thor
  include CMT::CliHelpers
  include Dry::Monads[:result]

  desc "fix_csv",
    "Updates batch archive CSV to add missing headers and delete removed "\
    "headers"
  def fix_csv
    if CMT.config.client.archive_batches
      report_result(
        CMT::ArchiveCsv::Fixer.call,
        failurelogic: ->(result) do
          puts "Fix FAILED: #{result.failure}"
          puts result.trace
        end
      )
    else
      puts "Batch archiving is not configured for this client"
      exit(1)
    end
  end
end
