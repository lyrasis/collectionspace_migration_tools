# frozen_string_literal: true

require "dry/monads"
require "thor"

# tasks targeting S3 bucket
class Bucket < Thor
  include CMT::CliHelpers
  include Dry::Monads[:result]

  desc "empty", "deletes all objects from bucket"
  def empty
    report_result(CMT::S3::Bucket.empty)
  end

  desc "objs", "returns keys of objects in bucket"
  def objs
    report_result(
      CMT::S3::Bucket.objects,
      successlogic: ->(result) { handle_list(result.value!) }
    )
  end

  desc "objct", "returns keys of objects in bucket"
  def objct
    report_result(CMT::S3::Bucket.objects(count_only: true))
  end

  desc "private", "sets policy of MEDIA INGEST bucket to private"
  def private
    report_result(
      CMT::S3::BucketPolicySetter.call(policy: :private),
      successlogic: report_success
    )
  end

  desc "public", "sets policy of MEDIA INGEST bucket to public for ingest"
  def public
    report_result(
      CMT::S3::BucketPolicySetter.call(policy: :public),
      successlogic: report_success
    )
  end

  no_commands do
    def handle_list(list)
      if list.empty?
        puts "Empty bucket"
      else
        puts list
        puts "Object count: #{list.length}"
      end
      exit(0)
    end

    def report_success = ->(_default) { puts "Success" }
  end
end
