# frozen_string_literal: true

require "thor"

class Decode < Thor
  include CMT::CliHelpers

  desc "objects", "decodes object keys of all objects in S3 bucket"
  def objects
    report_result(CMT::S3::ObjKeyDecoder.call(mode: :csv))
  end

  desc "key KEY", "decodes S3 object key; useful for debugging, etc."
  def key(key)
    report_result(CMT::Decode.key(key))
  end
end
