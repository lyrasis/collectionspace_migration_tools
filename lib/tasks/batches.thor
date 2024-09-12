# frozen_string_literal: true

require "fileutils"
require "thor"

# tasks targeting batches and batch csv
class Batches < Thor
  include Dry::Monads[:result]

  desc "fix_csv",
    "Updates batch-tracking CSV to add missing headers and derive "\
    "automatically generated values"
  def fix_csv
    CMT::Batch::Csv::Fixer.call.either(
      ->(ok) {
        puts ok
        exit(0)
      },
      ->(failure) {
        puts "Fix FAILED: #{failure}"
        exit(1)
      }
    )
  end

  desc "init_csv",
    "Creates new batch-tracking CSV if one does not exist. Checks existing "\
    "has up-to-date format"
  def init_csv
    CMT::Batch::Csv::Creator.call.either(
      ->(success) {
        puts "Wrote new file at #{CMT.config.client.batch_csv}"
        exit(0)
      },
      ->(failure) do
        path = CMT.config.client.batch_csv
        FileUtils.rm(path) if File.exist?(path)
        puts failure
        exit(1)
      end
    )
  end

  desc "delete_done", "Delete completed batches"
  def delete_done
    CMT::Batches.delete_done.either(
      ->(success) { exit(0) },
      ->(failure) {
        puts failure
        exit(1)
      }
    )
  end

  desc "done", "Brief listing of batches that are done"
  def done
    batch_lister(:done?)
  end

  desc "ingstat", "Checks ingest status of all batches that have been "\
    "uploaded but not successfully ingest checked"
  option :sleep, required: false, type: :numeric, default: 1.5
  option :checks, required: false, type: :numeric, default: 1
  option :rechecks, required: false, type: :numeric, default: 1
  option :dupedelete, required: false, type: :boolean, default: false
  def ingstat
    CMT::Batches.ingstat(
      wait: options[:sleep],
      checks: options[:checks],
      rechecks: options[:rechecks],
      autodelete: options[:dupedelete]
    ).either(
      ->(success) { exit(0) },
      ->(failure) {
        puts failure
        exit(1)
      }
    )
  end

  desc "map", "Maps all mappable batches to CS XML files"
  option :autocache, required: false, type: :boolean
  option :clearcache, required: false, type: :boolean
  def map
    CMT::Batches.map(options[:autocache], options[:clearcache]).either(
      ->(success) { exit(0) },
      ->(failure) {
        puts failure
        exit(1)
      }
    )
  end

  desc "show", "Brief listing of batch ids and info"
  def show
    CMT::Batch::Csv::Reader.new.to_cli_table
  end

  desc "to_ingstat",
    "Brief listing of batches uploaded and needing ingest status check"
  def to_ingstat
    batch_lister(:ingestable?)
  end

  desc "to_map", "Brief listing of batches ready to map"
  def to_map
    batch_lister(:mappable?)
  end

  desc "to_upload", "Brief listing of batches ready to upload"
  def to_upload
    batch_lister(:uploadable?)
  end

  desc "upload", "Uploads all mapped batches' CS XML to S3 bucket"
  def upload
    CMT::Batches.upload.either(
      ->(success) { exit(0) },
      ->(failure) {
        puts failure
        exit(1)
      }
    )
  end

  no_commands do
    def batch_lister(status)
      reader = CMT::Batch::Csv::Reader.new
      reader.find_status(status).either(
        ->(success) {
          reader.to_cli_table(success)
          exit(0)
        },
        ->(failure) {
          puts failure
          exit(1)
        }
      )
    end
  end
end
