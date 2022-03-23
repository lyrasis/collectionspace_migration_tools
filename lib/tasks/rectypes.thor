# frozen_string_literal: true

require 'thor'

# tasks targeting CS XML payloads
class Rectypes < Thor

  desc 'c_auth', 'list CACHEABLE authority rectype values'
  def c_auth
    puts CMT::RecordTypes.authority
  end

  desc 'c_proc', 'list CACHEABLE procedure rectype values and short codes for CLI use'
  def c_proc
    CMT::RecordTypes.procedures.sort_by{ |_k, v| v }.each do |key, value|
      puts "#{value} | Shortcut: #{key}"
    end
  end

  desc 'map', 'list MAPPABLE rectypes'
  def map
    puts CMT::RecordTypes.mappable
  end
end

