# frozen_string_literal: true

require "fileutils"
require "thor"

# tasks targeting batches and batch csv
class TermManager < Thor
  include Dry::Monads[:result]

  desc "config", "Display config for project"
  option :project, required: true, type: :string, aliases: "-p"
  def config
    cfg = CMT::TermManager.config(options[:project])
    unless cfg
      puts "Cannot parse/set up config"
      exit(1)
    end
    pp(cfg)
  end
  end
end
