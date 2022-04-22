# frozen_string_literal: true

require 'thor'

# tasks targeting a single batch
class Batch < Thor
  include Dry::Monads[:result]

  desc 'add', 'Adds a new batch to batch csv. ID must be <= 6 alphanumeric characters'
  option :id, required: true, type: :string
  option :csv, required: true, type: :string
  option :rectype, required: true, type: :string
  option :action, required: true, type: :string
  def add
    CMT::Batch::Add.call(id: options[:id], csv: options[:csv], rectype: options[:rectype], action: options[:action]).either(
      ->(success){ put_added(success) },
      ->(failure){ puts failure.to_s }
    )
  end

  desc 'cb BATCHID', '(C)lear (b)ucket. Delete objects from this batch from S3 bucket'
  def cb(id)
    CMT::S3::Bucket.empty(id).either(
      ->(success){ puts success.to_s },
      ->(failure){ puts failure.to_s }
    )
  end
  
  desc 'delete BATCHID', 'Removes batch row from batches CSV and deletes batch directory'
  def delete(id)
    CMT::Batch.delete(id).either(
      ->(success){  },
      ->(failure){ puts failure.to_s }
    )
  end

  desc 'done BATCHID', 'Mark this batch as done. No special workflow status checks are done'
  def done(id)
    CMT::Batch.done(id).either(
      ->(success){ puts "Done batches:"; invoke('batches:done', []) },
      ->(failure){ puts failure.to_s }
    )
  end

  option :sleep, required: false, type: :numeric, default: 1.5
  option :checks, required: false, type: :numeric, default: 1
  option :rechecks, required: false, type: :numeric, default: 1
  option :dupedelete, required: false, type: :boolean, default: false
  desc 'ingstat BATCHID', 'Checks ingest status, plus. Do `thor help batch:ingstat` for details'
  long_desc(File.read(File.join(Bundler.root, 'lib', 'tasks', 'batch_ingstat.txt')))
  def ingstat(id)
    CMT::Batch::IngestCheckRunner.call(
      batch_id: id,
      wait: options[:sleep],
      checks: options[:checks],
      rechecks: options[:rechecks],
      autodelete: options[:dupedelete]
    ).either(
      ->(success){  },
      ->(failure){ puts failure.to_s }
    )
  end
  
  desc 'map BATCHID', "Maps a batch's source CSV data to CS XML files"
  option :autocache, required: false, type: :boolean, default: CMT.config.client.auto_refresh_cache_before_mapping
  option :clearcache, required: false, type: :boolean, default: CMT.config.client.clear_cache_before_refresh
  def map(id)
    CMT::Batch.map(id, options[:autocache], options[:clearcache]).either(
      ->(success){  },
      ->(failure){ puts failure.to_s }
    )
  end

  desc 'rb_ingest BATCHID', "Clears the ingest-related columns for the batch in batches CSV and deletes any ingest reports"
  def rb_ingest(id)
    CMT::Batch.rollback_ingest(id).either(
      ->(success){ puts success },
      ->(failure){ puts failure.to_s}
    )
  end

  desc 'rb_map BATCHID', "Clears the mapping-related columns for the batch in batches CSV and deletes mapping reports"
  def rb_map(id)
    CMT::Batch.rollback_map(id).either(
      ->(success){ puts success },
      ->(failure){ puts failure.to_s}
    )
  end

  desc 'rb_upload BATCHID', "Clears the upload-related columns for the batch in batches CSV and deletes upload report. NOTE this does NOT undo any ingest operations triggered by successfully uploaded records"
  def rb_upload(id)
    CMT::Batch.rollback_upload(id).either(
      ->(success){ puts success },
      ->(failure){ puts failure.to_s}
    )
  end
  
  desc 'show BATCHID', 'Shows batch data currently in batches CSV'
  def show(id)
    CMT::Batch.find(id).either(
      ->(batch){ batch.show_info },
      ->(failure){ puts failure.to_s}
    )
  end

  desc 'upload BATCHID', "Uploads a batch's CS XML to S3 bucket"
  def upload(id)
    CMT::Batch::UploadRunner.call(batch_id: id).either(
      ->(success){ },
      ->(failure){ puts failure.to_s }
    )
  end
  
  no_commands do
    def put_added(success)
      puts "Successfully added batch with the following info:"
      success.each{ |key, val| puts "  #{key}: #{val}" }
    end
  end
end

