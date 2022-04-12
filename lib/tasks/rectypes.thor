# frozen_string_literal: true

require 'thor'

# tasks for listing record types for reference
class Rectypes < Thor
  desc 'list', 'list cacheable/mappable rectypes'
  def list
    puts CMT::RecordTypes.mappable
  end
end

