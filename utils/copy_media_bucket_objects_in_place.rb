# frozen_string_literal: true

# rubocop:disable Lint/UselessAssignment, Lint/Void
require "bundler/inline"

gemfile do
  source "https://rubygems.org"
  gem "pry"
end

# S3 path prefix to add to each filename. This will be the name of the media
# ingest bucket, wrapped in "s3://" and "/"
prefix = "s3://cspace-westerville-incoming/"

# Path to file listing all file names/paths in the bucket. Each line should have
# all identifying info needed to location the file after the `prefix` value
infile = "s3_cp_failures.csv"

# Path to file where log file will be written
outfile = "s3_cp.log"

# AWS profile name to use in the command
profile = "wpl"

files = File.new(infile)
  .readlines(chomp: true)
  .map { |fn| "#{prefix}#{fn}" }

def command(fn)
  system("aws s3 cp #{fn} #{fn} --profile #{profile} --copy-props none",
    exception: true)
rescue => err
  err
else
  :ok
end

File.open(outfile, "w") do |log|
  files.each do |fn|
    result = command(fn)
    if result == :ok
      log.puts("ok\t#{fn}")
    else
      log.puts("fail\t#{fn}\t#{result.message}")
    end
  end
end
# rubocop:enable Lint/UselessAssignment, Lint/Void
