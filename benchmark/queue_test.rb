# frozen_string_literal: true

require "smarter_csv"
require "debug"

csv_path = "/Users/kristina/data/CSWS/cs/collectionobject.csv"
csv_chunks = Queue.new

def populate_csv_chunks(csv_path, csv_chunks)
  SmarterCSV.process(
    csv_path, {
      chunk_size: 10,
      convert_values_to_numeric: false,
      strings_as_keys: true
    }
  ) do |chunk|
    csv_chunks << chunk
  end
end

populate_csv_chunks(csv_path, csv_chunks)

debugger
