# frozen_string_literal: true

require 'dry/monads'
require 'fileutils'
require 'thor'

# tasks targeting batches and batch csv
class Batches < Thor
  include Dry::Monads[:result]
  
  desc 'init_csv', 'Creates new batch-tracking CSV if one does not exist. Checks existing has up-to-date format'
  def init_csv
    path = CMT.config.client.batch_csv
    CMT::Batch::Csv::Creator.call.either(
      ->(success){ puts "Wrote new file at #{path}" },
      ->(failure){ FileUtils.rm(path) if File.exists?(path); puts failure.to_s }
    )
  end

  desc 'list', 'Brief listing of batch ids and info'
  def list
    CMT::Batch::Csv::Reader.new.list
  end
end

