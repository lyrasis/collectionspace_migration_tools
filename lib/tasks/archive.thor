# frozen_string_literal: true

require "fileutils"
require "thor"

# Tasks targeting batches archive CSV
class Archive < Thor
  include Dry::Monads[:result]

  desc "fix_csv",
    "Updates batch archive CSV to add missing headers and delete removed "\
    "headers"
  def fix_csv
    if CMT.config.client.archive_batches
      CMT::ArchiveCsv::Fixer.call.either(
        ->(ok) {
          puts ok
          exit(0)
        },
        ->(failure) {
          puts "Fix FAILED: #{failure}"
          exit(1)
        }
      )
    else
      puts "Batch archiving is not configured for this client"
      exit(1)
    end
  end
end
