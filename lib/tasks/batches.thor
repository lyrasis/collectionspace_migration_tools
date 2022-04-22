# frozen_string_literal: true

require 'fileutils'
require 'thor'

# tasks targeting batches and batch csv
class Batches < Thor
  include Dry::Monads[:result]
  
  desc 'fix_csv', 'Updates batch-tracking CSV to add missing headers and derive automatically generated values'
  def fix_csv
    CMT::Batch::Csv::Fixer.call.either(
      ->(ok){ puts ok; exit(0) },
      ->(failure){ puts "Fix FAILED: #{failure.to_s}"; exit(1) }
    )
  end
  
  desc 'init_csv', 'Creates new batch-tracking CSV if one does not exist. Checks existing has up-to-date format'
  def init_csv
    path = CMT.config.client.batch_csv
    CMT::Batch::Csv::Creator.call.either(
      ->(success){ puts "Wrote new file at #{path}"; exit(0) },
      ->(failure) do
        FileUtils.rm(path) if File.exists?(path)
        puts failure.to_s
        exit(1)
      end
    )
  end

  # @todo fix this so it uses do notation and it cleanly exitable
  desc 'delete_done', 'Delete completed batches'
  def delete_done
    done_batches = CMT::Batch::Csv::Reader.new.find_status(:is_done?)
    puts done_batches.failure.to_s if done_batches.failure?

    done_batches.value!.each do |batch|
      del = batch.delete
      puts del.failure.to_s if del.failure?
    end
  end
    
  desc 'done', 'Brief listing of batches that are done'
  def done
    batch_lister(:is_done?)
  end

  desc 'ingstat', 'Checks ingest status of all batches that have been uploaded but not successfully ingest checked'
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
      ->(success){ exit(0) },
      ->(failure){ puts failure.to_s; exit(1) }
    )
  end

  desc 'map', "Maps all mappable batches to CS XML files"
  option :autocache, required: false, type: :boolean, default: CMT.config.client.auto_refresh_cache_before_mapping
  option :clearcache, required: false, type: :boolean, default: CMT.config.client.clear_cache_before_refresh
  def map
    CMT::Batches.map(options[:autocache], options[:clearcache]).either(
      ->(success){ exit(0) },
      ->(failure){ puts failure.to_s; exit(1) }
    )
  end

  desc 'mark_done', 'Mark done any batches with all steps completed'
  def mark_done
    CMT::Batch::Csv::DoneMarker.call.either(
      ->(success){ puts "Batches marked done: #{success.join(', ')}"; exit(0) },
      ->(failure){ puts failure.to_s; exit(1) }
    )
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
        ->(success){ success.each{ |batch| puts batch.printable_row }; exit(0) },
        ->(failure){ puts failure.to_s; exit(1) }
      )
    end
  end
end

