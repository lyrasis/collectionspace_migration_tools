# frozen_string_literal: true

require 'dry/monads'
require 'thor'

# tasks related to verifying media ingest
class Media < Thor
  include Dry::Monads[:result]

  desc 'blob_data', 'writes CSV of media identificationnumber and '\
                    'blob data, if present'
  def blob_data
    CMT::Media.blob_data_report.either(
      ->(success){ exit(0) },
      ->(failure){ puts failure.to_s; exit(1) }
    )
  end
end
