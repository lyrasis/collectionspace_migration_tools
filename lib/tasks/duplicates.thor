# frozen_string_literal: true

require "thor"

# tasks targeting duplicate CS entities
class Duplicates < Thor
  include Dry::Monads[:result]
  include Dry::Monads::Do.for(:do_check)

  desc "check RECTYPE", "check rectype for duplicates"
  def check(rectype)
    CMT::Duplicate::Checker.call(rectype: rectype)
      .either(
        ->(results) { exit(0) },
        ->(failure) {
          puts failure
          exit(1)
        }
      )
  end
  end

  desc "delete RECTYPE",
    "deletes all duplicate records of a given mappable rectype"
  def delete(rectype)
    CMT::Duplicate::Deleter.call(rectype: rectype).either(
      ->(success) { exit(0) },
      ->(failure) { puts failure, exit(1) }
    )
  end
end
