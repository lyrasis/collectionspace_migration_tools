# frozen_string_literal: true

require 'thor'

# tasks targeting CS XML payloads
class Rectypes < Thor

  desc 'auth', 'list available authority rectype values'
  def auth
    puts CMT::RecordTypes.authority
  end

  desc 'oap', 'list available object and procedure rectype values and short codes for CLI use'
  def oap
    CMT::RecordTypes.objects_and_procedures.keys.sort.each do |key|
      puts "#{key} | Shortcut: #{CMT::RecordTypes.objects_and_procedures[key]}"
    end
  end
end

