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
  def csv
    ENV['RUBY_DEBUG_FORK_MODE'] = 'parent'
    start_time = Time.now
    
    processor = CMT::Csv::BatchProcessorPreparer.new(
      csv_path: options[:csv],
      rectype: options[:rectype],
      action: options[:action]
    ).call

    if processor.failure?
      puts processor.failure
      exit
    else
    processor.value!.call.either(
      ->(processor){ puts "Mapping completed." },
      ->(processor){ puts "PROCESSING FAILED: #{processor.context}: #{processor.message}"; exit } 
    )
    end

    puts "Total elapsed time: #{Time.now - start_time}"
  end
end
