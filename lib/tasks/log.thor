# frozen_string_literal: true

require "dry/monads"
require "thor"

# tasks targeting AWS Logs
class Log < Thor
  include CMT::CliHelpers
  include Dry::Monads[:result]

  desc "last_event", "Returns time of last logged event for import bucket"
  def last_event
    report_result(CMT::Logs::LastEventTime.call)
  end
  desc "logstream_report", "Write report with n start/end events for each "\
    "logstream in log group"
  option :start,
    default: 25,
    type: :numeric,
    desc: "The number of initial events from the logstream to output in "\
    "report. Set to 0 to skip output of first events.",
    aliases: "-s"
  option :end,
    default: 25,
    type: :numeric,
    desc: "The number of initial events from the logstream to output in "\
    "report. Set to 0 to skip output of final events.",
    aliases: "-e"
  option :path,
    required: true,
    type: :string,
    desc: "Path where output file will be written",
    aliases: "-o"
  def logstream_report
    fullpath = File.expand_path(options[:path])
    report_result(
      CMT::Logs::LogstreamReport.call(options[:start], options[:end], fullpath),
      successlogic: ->(_result) { puts "Written: #{fullpath}" }
    )
  end
end
