# frozen_string_literal: true

require "thor"

# tasks targeting duplicate CS entities
class Duplicates < Thor
  include CMT::CliHelpers
  include Dry::Monads[:result]
  include Dry::Monads::Do.for(:do_check)

  desc "check RECTYPE", "check rectype for duplicates"
  def check(rectype)
    report_result(CMT::Duplicate::Checker.call(rectype: rectype))
  end

  desc "check_all", "checks all rectypes for duplicates, and writes any "\
    "found to `base_dir/duplicate_reports`"
  def check_all
    CMT::Duplicate.check_all_and_write_reports
  end

  desc "delete RECTYPE",
    "deletes all duplicate records of a given mappable rectype"
  def delete(rectype)
    report_result(
      CMT::Duplicate::Deleter.call(rectype: rectype),
      failurelogic: ->(result) { result.failure.each { |f| puts f } }
    )
  end
end
