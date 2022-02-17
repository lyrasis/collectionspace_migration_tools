# frozen_string_literal: true

ruby File.read('.ruby-version').strip

source 'https://rubygems.org'
git_source(:github){ |repo_name| "https://github.com/#{repo_name}" }

gem 'benchmark-memory', '~> 0.2'
#gem 'collectionspace-client', tag: 'v0.13.4', git: 'https://github.com/collectionspace/collectionspace-client.git'
gem 'collectionspace-client', branch: 'master', git: 'https://github.com/collectionspace/collectionspace-client.git'
#gem 'collectionspace-mapper', tag: 'v3.0.0', git: 'https://github.com/collectionspace/collectionspace-mapper.git'
gem 'collectionspace-mapper', branch: 'migration-tooling', git: 'https://github.com/collectionspace/collectionspace-mapper.git'
#gem 'collectionspace-refcache', tag: 'v0.7.7', git: 'https://github.com/collectionspace/collectionspace-refcache.git'
gem 'collectionspace-refcache', branch: 'migration-tooling', git: 'https://github.com/collectionspace/collectionspace-refcache.git'
gem 'dry-monads', '~> 1.4'
gem 'dry-transaction', '~>0.13'
gem 'dry-validation', '~> 1.7'
gem 'pg', '~> 1.3'
gem 'redis', '~> 4.2.1'
gem 'refinements', '~> 9.1'
gem 'thor', '~> 1.2'
gem 'zeitwerk', '~> 2.5'

group :code_quality do
  gem 'bundler-leak', '~> 0.2'
  gem 'dead_end', '~> 3.0'
  gem 'git-lint', '~> 3.0'
  gem 'reek', '~> 6.1'
  gem 'rubocop', '~> 1.25'
  gem 'rubocop-performance', '~> 1.12'
  gem 'rubocop-rake', '~> 0.6'
  gem 'rubocop-rspec', '~> 2.6'
  gem 'simplecov', '~> 0.21'
end

group :development do
  gem 'asciidoctor', '~> 2.0'
  gem 'rake', '~> 13.0'
  gem 'yard', '~> 0.9'
  gem 'time_up'
end

group :test do
  gem 'guard-rspec', '~> 4.7', require: false
  gem 'mock_redis', '~> 0.29'
  gem 'rspec', '~> 3.10'
end

group :tools do
  gem 'amazing_print', '~> 1.4'
  gem 'debug', '~> 1.4'
end
