# frozen_string_literal: true

require 'dry/monads'
require 'thor'

# tasks targeting CS XML payloads
class Map < Thor
  include Dry::Monads[:result]
  include CMT::CliHelpers::Map
  
  desc 'csv', 'map rows of a CSV to CS XML files'
  option :csv, required: true, type: :string
  option :rectype, required: true, type: :string
  option :action, required: true, type: :string
  option :involved, required: false, type: :array
  def csv
    rectype = options[:rectype]
    unless options[:involved]
      require_involved(rectype) if rectype == 'authorityhierarchy' || rectype == 'nonhierarchicalrelationship'
    end
    process(options[:csv], rectype, options[:action])
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
