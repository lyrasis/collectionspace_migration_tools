# frozen_string_literal: true

ruby File.read(".ruby-version").strip

source "https://rubygems.org"
# git_source(:github){ |repo_name| "https://github.com/#{repo_name}" }

gem "aws-sdk-s3"
gem "aws-sdk-cloudwatchlogs"
gem "benchmark-memory"
gem "collectionspace-client",
  branch: "main",
  github: "collectionspace/collectionspace-client"
gem "collectionspace-mapper",
  branch: "migration-tools",
  github: "collectionspace/collectionspace-mapper"
gem "collectionspace-refcache",
  tag: "v1.0.0",
  github: "collectionspace/collectionspace-refcache"
gem "cspace_hosted_instance_access",
  github: "dts-hosting/cspace_hosted_instance_access",
  branch: "main"
gem "dry-monads"
gem "dry-transaction"
gem "dry-validation"
# @todo See https://github.com/mime-types/mime-types-data/pull/50
# `mime-types-data` is a dependency of `mime-types` < `httparty` <
#   `collectionspace-client`
gem "mime-types-data", "3.2021.1115"
gem "parallel"
gem "pg"
gem "redis"
gem "roo"
gem "ruby-progressbar"
gem "smarter_csv"
gem "tabulo"
gem "thor"
gem "zeitwerk"

group :development do
  gem "amazing_print"
  gem "asciidoctor"
  gem "almost_standard", github: "kspurgin/almost_standard", branch: "main"
  gem "bundler-leak"
  gem "dead_end"
  gem "debug"
  gem "rake"
  gem "reek"
  gem "simplecov"
  gem "time_up"
  gem "yard"
end

group :test do
  gem "guard-rspec", require: false
  gem "mock_redis"
  gem "rspec"
end

gem "pry", groups: [:development, :test]
