# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'
require 'thor'

# tasks targeting ingest process
class Ingest < Thor
  include Dry::Monads[:result]
  include Dry::Monads::Do.for(:do_report)
  
  desc 'report', 'adds ingest status columns to upload_report in new ingest_report file'
  option :batchdir, required: true, type: :string
  def report
    do_report(options[:batchdir]).either(
      ->(success){ puts "Ingest report written to #{success}" },
      ->(failure){ puts failure.to_s }
    )
  end

  no_commands do
    def do_report(dir)
      list = yield(CMT::S3::BucketLister.call)
      reported = yield(CMT::Ingest::Reporter.call(output_dir: dir, bucket_list: list))

      Success(reported)
    end
  end
end
