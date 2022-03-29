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
    processor_setup = CMT::Csv::BatchProcessorPreparer.new(
      csv_path: options[:csv],
      rectype: options[:rectype],
      action: options[:action]
    )
    processor_setup.call.either(
      ->(processor){ processor.call },
      ->(processor) do
        puts processor
        exit
      end
    )
  end
end
