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
  def csv
    check_file(options[:csv]).bind do |pathname|
      puts pathname.inspect
    end
  end
end
