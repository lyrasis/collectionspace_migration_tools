# frozen_string_literal: true

require 'dry/monads'
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
  
  desc 'show', 'Brief listing of batch ids and info'
  def show
    CMT::Batch::Csv::Reader.new.list
  end

  desc 'to_ingcheck', 'Brief listing of batches uploaded and needing ingest check'
  def to_ingcheck
    CMT::Batch::Csv::Reader.new.find_status(:ingestable?)
  end

  desc 'to_map', 'Brief listing of batches ready to map'
  def to_map
    CMT::Batch::Csv::Reader.new.find_status(:mappable?)
  end

  desc 'to_upload', 'Brief listing of batches ready to upload'
  def to_upload
    CMT::Batch::Csv::Reader.new.find_status(:uploadable?)
  end
end

