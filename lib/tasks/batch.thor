# frozen_string_literal: true

require "thor"

# tasks targeting a single batch
class Batch < Thor
  include Dry::Monads[:result]

  desc "add",
    "Adds a new batch to batch csv"
  option :id, required: true, type: :string,
    desc: "6-or-fewer-character-length code to identify the batch"
  option :csv, required: true, type: :string,
    desc: "Name of file in default client :ingest_dir or full path of file "\
    "anywhere"
  option :rectype, required: true, type: :string,
    desc: "do `thor rt:all` for list of valid values"
  option :action, required: true, type: :string,
    desc: "create, update, or delete"

  def add
    CMT::Batch::Add.call(
      id: options[:id],
      csv: options[:csv],
      rectype: options[:rectype],
      action: options[:action]
    ).either(
      ->(success) {
        put_added(success)
        exit(0)
      },
      ->(failure) {
        puts failure
        exit(1)
      }
    )
  end

  desc "cb BATCHID",
    "(C)lear (b)ucket. Delete objects from this batch from S3 bucket"
  def cb(id)
    CMT::S3::Bucket.empty(id).either(
      ->(success) {
        puts success
        exit(0)
      },
      ->(failure) {
        puts failure
        exit(1)
      }
    )
  end

  desc "lb BATCHID",
    "(L)ist (b)ucket. List keys of objects from this batch in S3 bucket"
  def lb(id)
    CMT::S3::Bucket.batch_objects(id).either(
      ->(success) {
        puts success
        puts "Total: #{success.length}"
        exit(0)
      },
      ->(failure) {
        puts failure
        exit(1)
      }
    )
  end

  desc "delete BATCHID",
    "Removes batch row from batches CSV and deletes batch directory"
  def delete(id)
    CMT::Batch.delete(id).either(
      ->(success) { exit(0) },
      ->(failure) {
        puts failure
        exit(1)
      }
    )
  end

  option :sleep, required: false, type: :numeric, default: 1.5
  option :checks, required: false, type: :numeric, default: 1
  option :rechecks, required: false, type: :numeric, default: 1
  option :dupedelete, required: false, type: :boolean, default: false
  desc "ingstat BATCHID",
    "Checks ingest status, plus. Do `thor help batch:ingstat` for details"
  long_desc(File.read(File.join(Bundler.root, "lib", "tasks",
    "batch_ingstat.txt")))
  def ingstat(id)
    CMT::Batch::IngestCheckRunner.call(
      batch_id: id,
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

  desc "map BATCHID", "Maps a batch's source CSV data to CS XML files"
  option :autocache, required: false, type: :boolean,
    default: CMT.config.client.auto_refresh_cache_before_mapping
  option :clearcache, required: false, type: :boolean,
    default: CMT.config.client.clear_cache_before_refresh
  def map(id)
    CMT::Batch.map(id, options[:autocache], options[:clearcache]).either(
      ->(success) { exit(0) },
      ->(failure) {
        puts failure
        exit(1)
      }
    )
  end

  desc "map_warnings BATCHID",
    "List unique warnings from batch mapper_report.csv"
  option :with_counts, required: false, type: :boolean, default: false
  def map_warnings(id)
    CMT::Batch::MapWarningsReporter.call(batch_id: id).either(
      ->(warnings) {
        options[:with_counts] ? report_warnings_with_counts(warnings) : report_warnings(warnings)
      },
      ->(failure) {
        puts failure
        exit(1)
      }
    )
  end

  desc "mtprep BATCHID",
    "Splits missing term report into term source specific CSVs and creates "\
    "batches to add terms"
  def mtprep(id)
    CMT::Batch.prep_missing_terms(id).either(
      ->(success) {
        if success == "No missing terms batches to create"
          puts "No missing authority terms. Check ingest or batch directory "\
            "for vocabulary terms to load"
        else
          puts "Created batches: #{success.join(", ")}"
          puts "Check ingest or batch directory for missing vocabulary terms "\
            "to load"
        end
        exit(0)
      },
      ->(failure) {
        puts failure
        exit(1)
      }
    )
  end

  desc "rb_ingstat BATCHID",
    "Clears the ingest-related columns for the batch in batches CSV and deletes any ingest reports"
  def rb_ingstat(id)
    CMT::Batch.rollback_ingest(id).either(
      ->(success) {
        puts success
        exit(0)
      },
      ->(failure) {
        puts failure
        exit(1)
      }
    )
  end

  desc "rb_map BATCHID",
    "Clears the mapping-related columns for the batch in batches CSV and deletes mapping reports"
  def rb_map(id)
    CMT::Batch.rollback_map(id).either(
      ->(success) {
        puts success
        exit(0)
      },
      ->(failure) {
        puts failure
        exit(1)
      }
    )
  end

  desc "rb_upload BATCHID",
    "Clears the upload-related columns for the batch in batches CSV and deletes upload report. NOTE this does NOT undo any ingest operations triggered by successfully uploaded records"
  def rb_upload(id)
    CMT::Batch.rollback_upload(id).either(
      ->(success) {
        puts success
        exit(0)
      },
      ->(failure) {
        puts failure
        exit(1)
      }
    )
  end

  desc "show BATCHID", "Shows batch data currently in batches CSV"
  def show(id)
    CMT::Batch.find(id).either(
      ->(batch) {
        puts batch
        exit(0)
      },
      ->(failure) {
        puts failure
        exit(1)
      }
    )
  end

  desc "upload BATCHID", "Uploads a batch's CS XML to S3 bucket"
  def upload(id)
    CMT::Batch::UploadRunner.call(batch_id: id).either(
      ->(success) { exit(0) },
      ->(failure) {
        puts failure
        exit(1)
      }
    )
  end

  no_commands do
    def put_added(success)
      puts "Successfully added batch with the following info:"
      success.each { |key, val| puts "  #{key}: #{val}" }
    end

    def report_warnings(warnings)
      puts warnings.keys.sort
      exit(0)
    end

    def report_warnings_with_counts(warnings)
      max_val_length = warnings.values.map(&:to_s).sort_by do |val|
        val.length
      end.last.length

      warnings.sort_by { |_key, val| val }
        .reverse_each { |key, val| puts "#{val.to_s.rjust(max_val_length)} : #{key}" }
      exit(0)
    end
  end
end
