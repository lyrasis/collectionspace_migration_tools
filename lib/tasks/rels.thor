# frozen_string_literal: true

require "thor"

# tasks for working with relations records
class Rels < Thor
  include Dry::Monads[:result]

  desc "check_nhrs", "check the status of given nonhierarchical relationships"
  long_desc <<-LONGDESC
    Takes path to a CSV containing at least the required columns for
    creating nonhierarchical relationships: item1_id, item1_type, item2_id,
    and item2_type. Any additional columns are returned in the resulting report,
    but are not required for functionality.

    Threaded API calls are made to check whether both reciprocal records exist
    for each row in the input file.

    Generates a report with two rows per original input row, indicating:

    - subject csid
    - object csid
    - csid of the relation record
    - exists = y/n
  LONGDESC
  option :inputpath,
    required: true,
    type: :string,
    banner: "/path/to/existing.csv",
    desc: "Path to CSV with columns required for creating NHRs",
    aliases: "-i"
  option :outputpath,
    type: :string,
    aliases: "-o",
    required: true,
    banner: "/path/to/output.csv",
    desc: "Path where result will be written. Should be a .csv"
  def check_nhrs
    inpath = Pathname.new(File.expand_path(options[:inputpath]))
    outpath = Pathname.new(File.expand_path(options[:outputpath]))

    unless File.exist?(inpath)
      puts "Input file #{inpath} does not exist"
      exit(1)
    end

    unless Dir.exist?(outpath.dirname)
      FileUtils.mkdir_p(outpath.dirname)
      puts "Created new directory: #{outpath.dirname}"
    end

    CMT::Rels::NhrChecker.call(input: inpath, output: outpath)
      .either(
        ->(success) { exit(0) },
        ->(failure) {
          puts failure
          exit(1)
        }
      )
  end
end
