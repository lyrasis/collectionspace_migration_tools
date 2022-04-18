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

  desc 'delete', 'Removes batch row from batches CSV and deletes batch directory'
  def delete(id)
    CMT::Batch.delete(id).either(
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

  desc 'show BATCHID', 'Shows batch data currently in batches CSV'
  def show(id)
    CMT::Batch.find(id).either(
      ->(batch){ batch.show_info },
      ->(failure){ puts failure.to_s}
    )
  end

  desc 'upload BATCHID', "Uploads a batch's CS XML to S3 bucket"
  def upload(id)
    CMT::Batch.dir(id).either(
      ->(dir){ invoke 'upload:dir', [dir] },
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

