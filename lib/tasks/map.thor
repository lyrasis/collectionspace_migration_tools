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
    CMT::Csv::BatchProcessRunner.call(csv: options[:csv], rectype: rectype, action: options[:action]).either(
      ->(success){ puts 'Processing complete' },
      ->(failure){ puts failure.to_s; exit }
    )
  end

  no_commands do
    # def cacheable
    # end

    # def require_involved(rectype)
    #   if rectype == 'authorityhierarchy'
    #     instruction = 'Enter one of the following:'
    #     values = CMT::RecordTypes.authority
    #   else
    #     instruction = 'From the following values, list all types involved in the relationships:'
    #     procedures = CMT::RecordTypes.procedures
    #     values = [procedures.keys, procedures.values, 'obj'].flatten.sort.uniq
    #   end

    #   puts "To map #{rectype}, you must also specify `--involved` option"
    #   puts instruction
    #   puts values.join(', ')
    #   exit
    # end
  end
end
