# frozen_string_literal: true

require 'dry/monads'
require 'thor'

# @note Commented out stuff was toward ensuring relevant caches were automatically updated prior to mapping
# tasks targeting CS XML payloads
class Map < Thor
  include Dry::Monads[:result]
  include CMT::CliHelpers::Map
  
  desc 'csv', 'map rows of a CSV to CS XML files'
  option :csv, required: true, type: :string
  option :rectype, required: true, type: :string
  option :action, required: true, type: :string
#  option :involved, required: false, type: :array
  def csv
    rectype = options[:rectype]
    CMT::Batch::MapRunner.call(csv: options[:csv], rectype: rectype, action: options[:action]).either(
      ->(success){ puts 'Processing complete'; exit(0) },
      ->(failure){ puts failure.to_s; exit(1) }
    )
  end
end
