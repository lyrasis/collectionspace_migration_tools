# frozen_string_literal: true

require "dry/monads"
require "thor"

# tasks targeting AWS Logs
class Log < Thor
  include Dry::Monads[:result]

  desc "last_event", "Returns time of last logged event for import bucket"
  def last_event
    CMT::Logs::LastEventTime.call.either(
      ->(success) {
        puts success
        exit(0)
      },
      ->(failure) {
        puts failure
        exit(1)
      }
    )
  end
  desc "logstream_report", "Write report with n start/end events for each "\
    "logstream in log group"
  option :start,
    default: 25,
    type: :numeric,
    desc: "The number of initial events from the logstream to output in "\
    "report. Set to 0 to skip output of first events."
  option :end,
    default: 25,
    type: :numeric,
    desc: "The number of initial events from the logstream to output in "\
    "report. Set to 0 to skip output of final events."
  option :path,
    required: true,
    type: :string,
    desc: "Path where output file will be written"
  def logstream_report
    fullpath = File.expand_path(options[:path])
    CMT::Logs::LogstreamReport.call(
      options[:start], options[:end], fullpath
    ).either(
      ->(success) {
        puts "Written: #{fullpath}"
        exit(0)
      },
      ->(failure) {
        puts failure
        exit(1)
      }
    )
  end
end
