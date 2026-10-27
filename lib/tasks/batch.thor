# frozen_string_literal: true

require "thor"

# tasks targeting a single batch
class Batch < Thor
  include CMT::CliHelpers
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
    report_result(
      CMT::Batch::Add.call(
        id: options[:id],
        csv: options[:csv],
        rectype: options[:rectype],
        action: options[:action]
      ),
      successlogic: put_added
    )
  end

  desc "cb BATCHID",
    "(C)lear (b)ucket. Delete objects from this batch from S3 bucket"
  def cb(id)
    report_result(CMT::S3::Bucket.empty(id))
  end

  desc "lb BATCHID",
    "(L)ist (b)ucket. List keys of objects from this batch in S3 bucket"
  def lb(id)
    report_result(
      CMT::S3::Bucket.batch_objects(id),
      successlogic: ->(result) do
        success = result.value!
        puts success
        puts "Total: #{success.length}"
      end
    )
  end

  desc "lbc BATCHID",
    "(L)ist (b)ucket (c)ount. Print just the number of objects in the bucket"
  def lbc(id)
    report_result(CMT::S3::Bucket.batch_objects(id, count_only: true))
  end

  desc "delete BATCHID",
    "Removes batch row from batches CSV and deletes batch directory"
  def delete(id)
    report_result(CMT::Batch.delete(id))
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
    report_result(
      CMT::Batch::IngestCheckRunner.call(
        batch_id: id,
        wait: options[:sleep],
        checks: options[:checks],
        rechecks: options[:rechecks],
        autodelete: options[:dupedelete]
      )
    )
  end

  desc "map BATCHID", "Maps a batch's source CSV data to CS XML files"
  option :autocache, required: false, type: :boolean
  option :clearcache, required: false, type: :boolean
  def map(id)
    report_result(CMT::Batch.map(id, options[:autocache], options[:clearcache]))
  end

  desc "map_warnings BATCHID",
    "List unique warnings from batch mapper_report.csv"
  option :with_counts, required: false, type: :boolean, default: false
  def map_warnings(id)
    report_result(
      CMT::Batch::MapWarningsReporter.call(batch_id: id),
      successlogic: report_map_warnings
    )
  end

  desc "mtprep BATCHID",
    "Splits missing term report into term source specific CSVs and creates "\
    "batches to add terms"
  def mtprep(id)
    report_result(
      CMT::Batch.prep_missing_terms(id),
      successlogic: mtprep_success
    )
  end

  desc "rb_ingstat BATCHID",
    "Clears the ingest-related columns for the batch in batches CSV and "\
    "deletes any ingest reports"
  def rb_ingstat(id)
    report_result(CMT::Batch.rollback_ingest(id))
  end

  desc "rb_map BATCHID",
    "Clears the mapping-related columns for the batch in batches CSV and "\
    "deletes mapping reports"
  def rb_map(id)
    report_result(CMT::Batch.rollback_map(id))
  end

  desc "rb_upload BATCHID",
    "Clears the upload-related columns for the batch in batches CSV and "\
    "deletes upload report. NOTE this does NOT undo any ingest operations "\
    "triggered by successfully uploaded records"
  def rb_upload(id)
    report_result(CMT::Batch.rollback_upload(id))
  end

  desc "show BATCHID", "Shows batch data currently in batches CSV"
  def show(id)
    report_result(CMT::Batch.find(id))
  end

  desc "upload BATCHID", "Uploads a batch's CS XML to S3 bucket"
  def upload(id)
    report_result(CMT::Batch::UploadRunner.call(batch_id: id))
  end

  no_commands do
    def mtprep_success
      ->(result) do
        success = result.value!
        if success == "No missing terms batches to create"
          puts "No missing authority terms. Check ingest or batch directory "\
            "for vocabulary terms to load"
        else
          puts "Created batches: #{success.join(", ")}"
          puts "Check ingest or batch directory for missing vocabulary terms "\
            "to load"
        end
      end
    end

    def put_added
      ->(result) do
        puts "Successfully added batch with the following info:"
        result.value!.each { |key, val| puts "  #{key}: #{val}" }
      end
    end

    def report_map_warnings
      return report_warnings_with_counts if options[:with_counts]

      report_warnings
    end

    def report_warnings
      ->(result) { puts result.value!.keys.sort }
    end

    def report_warnings_with_counts
      ->(result) do
        warnings = result.value!
        max_val_length = warnings.values.map(&:to_s).max_by do |val|
          val.length
        end.length

        warnings.sort_by { |_key, val| val }
          .reverse_each do |key, val|
            puts "#{val.to_s.rjust(max_val_length)} : #{key}"
          end
      end
    end
  end
end
