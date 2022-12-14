# frozen_string_literal: true

require 'dry/monads'
require 'thor'

# tasks that manipulate records directly via the API by CSID
class Csid < Thor
  include Dry::Monads[:result]

  desc 'delete', 'deletes records by CSID'
  long_desc <<-LONGDESC
    Takes path to a CSV containing at least `rectype` and `csid` columns.
    Any additional columns are returned in the resulting report, but are
    not required for functionality.

    `rectype` values should be mappable rectype (do `thor rt:all` for list)
    or `blob`. Multiple rectypes can be in the same CSV for deletion.

    Threaded API calls are made to delete the given records. A report is
    generated to indicate whether each deletion was a success or failure.
    Error messages are included in the report for failures.
  LONGDESC
  option :csv,
         type: :string,
         banner: '/path/to/csv',
         default: nil,
         desc: 'Path to CSV with `rectype` and `csid` columns'
  def delete
    CMT::Csid::DeleteHandler.call(csv_path: options[:csv])
      .either(
        ->(success){ exit(0) },
        ->(failure){ puts failure.to_s; exit(1) }
      )
  end
end
