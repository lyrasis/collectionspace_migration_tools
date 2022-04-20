# frozen_string_literal: true

require 'fileutils'
require 'thor'

# tasks targeting batches and batch csv
class Batches < Thor
  include Dry::Monads[:result]
  
  desc 'fix_csv', 'Updates batch-tracking CSV to add missing headers and derive automatically generated values'
  def fix_csv
    CMT::Batch::Csv::Fixer.call.either(
      ->(ok){ puts ok },
      ->(failure){ puts "Fix FAILED: #{failure.to_s}" }
    )
  end
  
  desc 'init_csv', 'Creates new batch-tracking CSV if one does not exist. Checks existing has up-to-date format'
  def init_csv
    path = CMT.config.client.batch_csv
    CMT::Batch::Csv::Creator.call.either(
      ->(success){ puts "Wrote new file at #{path}" },
      ->(failure){ FileUtils.rm(path) if File.exists?(path); puts failure.to_s }
    )
  end

  desc 'delete_done', 'Delete completed batches'
  def delete_done
    done_batches = CMT::Batch::Csv::Reader.new.find_status(:is_done?)
    puts done_batches.failure.to_s if done_batches.failure?

    done_batches.value!.each do |batch|
      del = batch.delete
      puts del.failure.to_s if del.failure?
    end
  end
    

  desc 'mark_done', 'Mark done any batches with all steps completed'
  def mark_done
    CMT::Batch::Csv::DoneMarker.call.either(
      ->(success){ puts "Batches marked done: #{success.join(', ')}" },
      ->(failure){ puts failure.to_s }
    )
  end

  desc 'done', 'Brief listing of batches that are done'
  def done
    batch_lister(:is_done?)
  end
  
  desc 'show', 'Brief listing of batch ids and info'
  def show
    CMT::Batch::Csv::Reader.new.list
  end

  desc 'to_ingcheck', 'Brief listing of batches uploaded and needing ingest check'
  def to_ingcheck
    batch_lister(:ingestable?)
  end

  desc 'to_map', 'Brief listing of batches ready to map'
  def to_map
    batch_lister(:mappable?)
  end

  desc 'to_upload', 'Brief listing of batches ready to upload'
  def to_upload
    batch_lister(:uploadable?)
  end

  no_commands do
    def batch_lister(status)
      CMT::Batch::Csv::Reader.new.find_status(status).either(
        ->(success){ success.each{ |batch| puts batch.printable_row } },
        ->(failure){ puts failure.to_s }
      )
    end
  end
end

