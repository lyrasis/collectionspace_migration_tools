# frozen_string_literal: true

require 'dry/monads'
require 'thor'

# tasks targeting S3 bucket
class Bucket < Thor
  include Dry::Monads[:result]
  
  desc 'list', 'returns keys of objects in bucket'
  def list
    CMT::S3::BucketLister.call.either(
      ->(list){ list.empty? ? puts "Empty bucket" : puts list },
      ->(failure){ puts failure.to_s; exit }
    )
  end
end
