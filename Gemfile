# frozen_string_literal: true

ruby File.read(".ruby-version").strip

source "https://rubygems.org"
# git_source(:github){ |repo_name| "https://github.com/#{repo_name}" }

gem "aws-sdk-s3", "~> 1"
gem "aws-sdk-cloudwatchlogs", "~> 1"
gem "benchmark-memory", "~> 0.2"
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
gem "dry-validation", "~> 1.11.1"
# @todo See https://github.com/mime-types/mime-types-data/pull/50
# `mime-types-data` is a dependency of `mime-types` < `httparty` <
#   `collectionspace-client`
gem "mime-types-data", "3.2021.1115"
gem "parallel", "~> 1.22"
gem "pg", "~> 1.4"
gem "redis", "~> 4.2.1"
gem "refinements", "~> 9.1"
gem "roo"
gem "smarter_csv", "~> 1.7.4"
gem "tabulo", "~> 3"
gem "thor", "~> 1"
gem "thor-hollaback", "~> 0"
gem "zeitwerk", "~> 2.5"

group :development do
  gem "amazing_print", "~> 1.4"
  gem "asciidoctor", "~> 2.0"
  gem "almost_standard", github: "kspurgin/almost_standard", branch: "main"
  gem "bundler-leak", "~> 0.2"
  gem "dead_end", "~> 3.0"
  gem "debug", "~> 1.4"
  gem "rake", "~> 13.0"
  gem "reek", "~> 6.1"
  gem "simplecov", "~> 0.21"
  gem "time_up"
  gem "yard", "~> 0.9"
end

group :test do
  gem "guard-rspec", require: false
  # Pinning mock_redis version because updating to 0.48.0 caused rspec errors
  gem "mock_redis", "0.36.0"
  gem "rspec"
end

gem "pry", "~> 0.14", groups: [:development, :test]
