# frozen_string_literal: true

require 'dry/monads'
require 'thor'

# tasks targeting S3 bucket
class Bucket < Thor
  include Dry::Monads[:result]
  
  desc 'list', 'returns keys of objects in bucket'
  def list
    CMT::S3::BucketLister.call.either(
      ->(list){ handle_list(list) },
      ->(failure){ puts failure.to_s; exit }
    )
  end

  no_commands do
    def handle_list(list)
      if list.empty?
        puts "Empty bucket"
      else
        puts list
      end
    end
  end
end
