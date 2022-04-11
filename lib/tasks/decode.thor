# frozen_string_literal: true

require 'base64'
require 'thor'

class Decode < Thor
  desc 'key KEY', 'decodes S3 object key; useful for debugging, etc.'
  def key(key)
    puts Base64.urlsafe_decode64(key)
  end
end
