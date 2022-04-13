# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'
require 'thor'

# tasks targeting a single batch
class Batch < Thor
  include Dry::Monads[:result]
  include Dry::Monads::Do.for(:do_delete, :do_map, :get_batch, :get_batch_dir)

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
    do_delete(id).either(
      ->(success){  },
      ->(failure){ puts failure.to_s }
    )
  end

  desc 'map BATCHID', "Maps a batch's source CSV data to CS XML files"
  option :autocache, required: false, type: :boolean, default: CMT.config.client.auto_refresh_cache_before_mapping
  option :clearcache, required: false, type: :boolean, default: CMT.config.client.clear_cache_before_refresh
  def map(id)
    do_map(id, options[:autocache], options[:clearcache]).either(
      ->(success){  },
      ->(failure){ puts failure.to_s }
    )
  end

  desc 'upload BATCHID', "Uploads a batch's CS XML to S3 bucket"
  def upload(id)
    get_batch_dir(id).either(
      ->(dir){ invoke 'upload:dir', [dir] },
      ->(failure){ puts failure.to_s }
    )
  end
  
  no_commands do
    def clear_caches
      invoke 'caches:clear', []
    rescue StandardError => err
      msg = "#{err.message} IN #{err.backtrace[0]}"
      Failure(CMT::Failure.new(context: "#{self.class.name}.#{__callee__}", message: msg))
    else
      Success()
    end

    def do_delete(id)
      batch = yield(get_batch(id))
      _deleted = yield(batch.delete)

      Success()
    end
    
    def do_map(id, autocache, clearcache)
      batch = yield(get_batch(id))
      plan = yield(CMT::Batch::CachingPlanner.call(batch)) if autocache
      if autocache && !plan.empty?
        _cc = yield(clear_caches) if autocache && clearcache
        _ac = yield(CMT::Batch::AutoCacher.call(plan)) if autocache
      end
      output = yield(CMT::Csv::BatchProcessRunner.call(
                       csv: batch.source_csv, rectype: batch.mappable_rectype, action: batch.action, batch: id
                     ))
      report = yield(CMT::Batch::PostMapReporter.new(batch: batch, dir: output).call)
      
      Success(report)
    end

    def get_batch(id)
      csv = yield(CMT::Batch::Csv.new)
      batch = yield(CMT::Batch::Batch.new(csv, id))

      Success(batch)
    end

    def get_batch_dir(id)
      batch = yield(get_batch(id))

      Success(batch.dir)
    end

    def put_added(success)
      puts "Successfully added batch with the following info:"
      success.each{ |key, val| puts "  #{key}: #{val}" }
    end

    def show_reported(success)
    end
  end
end

