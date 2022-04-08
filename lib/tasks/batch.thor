# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'
require 'thor'

# tasks targeting a single batch
class Batch < Thor
  include Dry::Monads[:result]
  include Dry::Monads::Do.for(:map)

  desc 'add', 'Adds a new batch to batch csv'
  option :id, required: true, type: :string
  option :csv, required: true, type: :string
  option :rectype, required: true, type: :string
  option :action, required: true, type: :string
  def add
    CMT::Batch::Add.call(id: options[:id], csv: options[:csv], rectype: options[:rectype], action: options[:action]).either(
      ->(success){ put_added(success) },
      ->(failure){ puts failure.to_s }
    )
  end

  desc 'map', "Maps a batch's source CSV data to CS XML files"
  option :id, required: true, type: :string
  def map
    csv = yield(CMT::Batch::Csv.new)
    batch = yield(CMT::Batch::Batch.new(csv, options[:id]))

    invoke 'map:csv', [], csv: batch.source_csv, rectype: batch.mappable_rectype, action: batch.action

    Success()
  end

  no_commands do
    def put_added(success)
      puts "Successfully added batch with the following info:"
      success.each{ |key, val| puts "  #{key}: #{val}" }
    end
  end
end

