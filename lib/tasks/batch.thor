# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'
require 'thor'

# tasks targeting a single batch
class Batch < Thor
  include Dry::Monads[:result]
  include Dry::Monads::Do.for(:do_map, :get_batch_dir)

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

  desc 'map BATCHID', "Maps a batch's source CSV data to CS XML files"
  def map(id)
    do_map(id).either(
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
    def do_map(id)
      csv = yield(CMT::Batch::Csv.new)
      batch = yield(CMT::Batch::Batch.new(csv, id))
      output = yield(CMT::Csv::BatchProcessRunner.call(
                       csv: batch.source_csv, rectype: batch.mappable_rectype, action: batch.action, batch: id
                     ))
      report = yield(CMT::Batch::PostMapReporter.new(batch: batch, dir: output).call)
      
      Success(report)
    end

    def get_batch_dir(id)
      csv = yield(CMT::Batch::Csv.new)
      batch = yield(CMT::Batch::Batch.new(csv, id))

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

