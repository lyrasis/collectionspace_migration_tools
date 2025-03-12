# frozen_string_literal: true

require "fileutils"
require "thor"

# tasks targeting batches and batch csv
class TermManager < Thor
  include Dry::Monads[:result]

  desc "config", "Display config for project"
  option :project, required: true, type: :string, aliases: "-p"
  def config
    CMT::TermManager.config(options[:project])
      .either(
      ->(success) { exit(0) },
      ->(failure) {
        puts failure
        exit(1)
      }
    )
  end
end
