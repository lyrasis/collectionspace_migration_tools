# frozen_string_literal: true

ruby File.read('.ruby-version').strip

source 'https://rubygems.org'

gem 'refinements', '~> 9.1'
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
end

group :test do
  gem 'guard-rspec', '~> 4.7', require: false
  gem 'rspec', '~> 3.10'
end

group :tools do
  gem 'amazing_print', '~> 1.4'
  gem 'debug', '~> 1.4'
end
