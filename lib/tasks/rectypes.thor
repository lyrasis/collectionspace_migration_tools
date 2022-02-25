# frozen_string_literal: true

require 'thor'

# tasks targeting CS XML payloads
class Rectypes < Thor

  desc 'auth', 'list available authority rectype values'
  def auth
    puts CMT::RecordTypes.authority
  end
end

