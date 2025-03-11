# frozen_string_literal: true

require "bundler/setup"
Bundler.require(:tools)

require "simplecov"
SimpleCov.start { enable_coverage :branch }

require_relative "./helpers"
require "collectionspace_migration_tools"
require "collectionspace/mapper"
require "pry"

require "refinements"
using Refinements::Pathnames
Pathname.require_tree(__dir__, "support/shared_contexts/**/*.rb")

RSpec.configure do |config|
  config.include Helpers
  config.color = true
  config.disable_monkey_patching!
  config.example_status_persistence_file_path = "./tmp/rspec-examples.txt"
  config.filter_run_when_matching(:focus)
  config.formatter = (ENV["CI"] == "true") ? :progress : :documentation
  config.order = :random
  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.warnings = true
  config.after(:each) { CMT.reset_config }

  config.expect_with(:rspec) do |expectations|
    expectations.syntax = :expect
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
    expectations.max_formatted_output_length = 2000
  end

  config.define_derived_metadata do |meta|
    meta[:aggregate_failures] = true
  end

  config.mock_with(:rspec) do |mocks|
    mocks.verify_doubled_constant_names = true
    mocks.verify_partial_doubles = true
  end
end
