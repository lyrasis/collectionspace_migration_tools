# frozen_string_literal: true

require "dry/monads"
require "thor"

# @note Commented out stuff was toward ensuring relevant caches were
#   automatically updated prior to mapping tasks targeting CS XML
#   payloads
class Map < Thor
  include CMT::CliHelpers
  include CMT::CliHelpers::Map
  include Dry::Monads[:result]

  desc "csv", "map rows of a CSV to CS XML files"
  option :csv, required: true, type: :string
  option :rectype, required: true, type: :string
  option :action, required: true, type: :string
  #  option :involved, required: false, type: :array
  def csv
    rectype = options[:rectype]
    report_result(
      CMT::Batch::MapRunner.call(
        csv: options[:csv], rectype: rectype, action: options[:action]
      ),
      successlogic: ->(_result) { puts "Processing complete" }
    )
  end
end
