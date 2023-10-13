# frozen_string_literal: true

require 'dry/monads'
require 'thor'

# tasks targeting AWS Logs
class Log < Thor
  include Dry::Monads[:result]

  desc 'last_event', 'Returns time of last logged event for import bucket'
  def last_event
    CMT::Logs::LastEventTime.call.either(
      ->(success){ puts success; exit(0) },
      ->(failure){ puts failure.to_s; exit(1) }
    )
  end
end
