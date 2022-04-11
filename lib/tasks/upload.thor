# frozen_string_literal: true

require 'dry/monads'
require 'thor'

# tasks targeting CS XML payloads
class Upload < Thor
  include Dry::Monads[:result]
  include CMT::CliHelpers::Map
  
  desc 'dir', 'uploads files in mapper output directory to S3 bucket for ingest'
  option :dir, required: true, type: :string
  def dir
    uploader = CMT::S3::UploaderPreparer.new(
      file_dir: options[:dir]
    ).call

    if uploader.failure?
      puts uploader.failure
      exit
    else
      uploader.value!.call.either(
        ->(uploader){ puts "Uploading completed. Remember this does NOT mean all files successfully uploaded, OR that all uploaded files were successfully ingested" },
        ->(uploader){ puts "UPLOADING FAILED: #{uploader.to_s}"; exit } 
      )
    end
  end
end

