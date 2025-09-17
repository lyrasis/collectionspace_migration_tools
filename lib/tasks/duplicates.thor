# frozen_string_literal: true

require "thor"

# tasks targeting duplicate CS entities
class Duplicates < Thor
  include Dry::Monads[:result]
  include Dry::Monads::Do.for(:do_check)

  desc "check RECTYPE", "check rectype for duplicates"
  def check(rectype)
    do_check(rectype).either(
      ->(results) {
        report_check(results)
        exit(0)
      },
      ->(failure) {
        puts failure
        exit(1)
      }
    )
  end

  desc "delete RECTYPE",
    "deletes all duplicate records of a given mappable rectype"
  def delete(rectype)
    CMT::Duplicate::Deleter.call(rectype: rectype).either(
      ->(success) { exit(0) },
      ->(failure) { puts failure, exit(1) }
    )
  end

  no_commands do
    def do_check(rectype)
      obj = yield(CMT::RecordTypes.to_obj(rectype))
      unless obj.respond_to?(:duplicates)
        return Failure("#{rectype} is not duplicate-checkable")
      end

      results = yield(obj.duplicates)

      Success(results)
    end

    def report_check(results)
      puts "#{results.num_tuples} duplicates"
    end
  end
end
