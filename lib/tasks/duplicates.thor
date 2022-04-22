# frozen_string_literal: true

require 'thor'

# tasks targeting duplicate CS entities
class Duplicates < Thor
  include Dry::Monads[:result]

  desc 'delete RECTYPE', 'deletes all duplicate records of a given mappable rectype'
  def delete(rectype)
    CMT::Duplicate::Deleter.call(rectype: rectype).either(
      ->(success){ exit(0) },
      ->(failure){ puts failure.to_s, exit(1) }
    )
  end
end
