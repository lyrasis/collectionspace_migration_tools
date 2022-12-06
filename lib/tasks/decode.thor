# frozen_string_literal: true

require 'thor'

class Decode < Thor
  desc 'objects', 'decodes object keys of all objects in S3 bucket'
  def objects
    CMT::S3::ObjKeyDecoder.call(mode: :csv).either(
      ->(success){ exit(0) },
      ->(failure){ puts failure.to_s; exit(1) }
    )
  end

  desc 'key KEY', 'decodes S3 object key; useful for debugging, etc.'
  def key(key)
    CMT::Decode.key(key).either(
      ->(success){ puts success; exit(0) },
      ->(failure){ puts failure.to_s; exit(1) }
    )
  end
end
