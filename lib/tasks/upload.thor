# frozen_string_literal: true

require 'dry/monads'
require 'thor'

# tasks targeting CS XML payloads
class Upload < Thor
  include Dry::Monads[:result]
  include CMT::CliHelpers::Map
  
  desc 'dir', 'uploads files in mapper output directory to S3 bucket for ingest'
  option :batchdir, required: true, type: :string
  def dir
    uploader = CMT::S3::UploaderPreparer.new(
      file_dir: options[:batchdir]
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

  no_commands do
    def cacheable
    end
    
    def process(csv, rectype, action)
      start_time = Time.now
      
      processor = CMT::Csv::BatchProcessorPreparer.new(
        csv_path: csv,
        rectype: rectype,
        action: action
      ).call

      if processor.failure?
        puts processor.failure
        exit
      else
        processor.value!.call.either(
          ->(processor){ puts "Mapping completed." },
          ->(processor){ puts "PROCESSING FAILED: #{processor.to_s}"; exit } 
        )
      end

      puts "Total elapsed time: #{Time.now - start_time}"
    end

    def require_involved(rectype)
      if rectype == 'authorityhierarchy'
        instruction = 'Enter one of the following:'
        values = CMT::RecordTypes.authority
      else
        instruction = 'From the following values, list all types involved in the relationships:'
        procedures = CMT::RecordTypes.procedures
        values = [procedures.keys, procedures.values, 'obj'].flatten.sort.uniq
      end

      puts "To map #{rectype}, you must also specify `--involved` option"
      puts instruction
      puts values.join(', ')
      exit
    end
  end
end
