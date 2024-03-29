# frozen_string_literal: true

require "dry/monads"
require "thor"

# tasks related to verifying media ingest
class Media < Thor
  include Dry::Monads[:result]

  desc "blob_data", "writes CSV of media identificationnumber and "\
                    "blob data, if present"
  def blob_data
    CMT::Media.blob_data_report.either(
      ->(success) { exit(0) },
      ->(failure) {
        puts failure
        exit(1)
      }
    )
  end

  desc "deriv_report", "writes CSV of derivative data"
  long_desc <<-LONGDESC
    Writes CSV report of derivatives for each blob attached to a media
    handling procedure to `{base_dir}/blob_derivative_report.csv`

    A `csv` path may be given. This should be a path to a CSV
    containing `blobcsid` and `mimetype` columns having values for all
    blobs you want to check derivatives for.

    If no `csv` path is given, it runs the `thor media blob_data`
    command and uses its output (i.e. ALL blobs attached to media in
    the client instance) as its input.

    This report relies on making a Services API call for every row, so
    it takes a long time to run.
  LONGDESC
  option :csv,
    type: :string,
    banner: "/path/to/csv",
    default: nil,
    desc: "Path to CSV with `blobcsid` & `mimetype` columns"
  def deriv_report
    CMT::Media::DerivReporter.call(csv_path: options[:csv])
      .either(
        ->(success) { exit(0) },
        ->(failure) {
          puts failure
          exit(1)
        }
      )
  end
end
