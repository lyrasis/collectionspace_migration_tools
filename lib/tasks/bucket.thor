# frozen_string_literal: true

require 'dry/monads'
require 'thor'

# tasks targeting S3 bucket
class Bucket < Thor
  include Dry::Monads[:result]

  desc 'empty', 'deletes all objects from bucket'
  def empty
    CMT::S3::Bucket.empty.either(
      ->(success){ puts success.to_s; exit(0) },
      ->(failure){ puts failure.to_s; exit(1) }
    )
  end

  desc 'objs', 'returns keys of objects in bucket'
  def objs
    CMT::S3::Bucket.objects.either(
      ->(list){ handle_list(list) },
      ->(failure){ puts failure.to_s; exit(1) }
    )
  end

  desc 'private', 'sets policy of MEDIA INGEST bucket to private'
  def private
    CMT::S3::BucketPolicySetter.call(policy: :private).either(
      ->(success){ puts "Success"; exit(0) },
      ->(failure){ puts failure.to_s; exit(1) }
    )
  end

  desc 'public', 'sets policy of MEDIA INGEST bucket to public for ingest'
  def public
    CMT::S3::BucketPolicySetter.call(policy: :public).either(
      ->(success){ puts "Success"; exit(0) },
      ->(failure){ puts failure.to_s; exit(1) }
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
  end
end
