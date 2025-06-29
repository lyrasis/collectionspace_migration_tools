# frozen_string_literal: true

require "fileutils"
require "thor"

# tasks targeting batches and batch csv
class TermManager < Thor
  include Dry::Monads[:result]
  namespace :tm

  desc "config", "Display config for TermManager project"
  option :project, required: true, type: :string, aliases: "-p"
  def config
    work_in_progress

    cfg = CMT::TermManager.config(options[:project])
    unless cfg
      puts "Cannot parse/set up config"
      exit(1)
    end
    pp(cfg)
  end

  desc "work_plan", "Display work plan for TermManager project"
  option :project, required: true, type: :string, aliases: "-p"
  option :instances, required: false, type: :array, aliases: "-i"
  option :term_sources, required: false, type: :array, aliases: "-s"
  def work_plan
    work_in_progress

    params = {project: CMT::TermManager::Project.new(options[:project]),
              instances: options[:instances],
              term_sources: options[:term_sources]}.compact
    pp(CMT::TermManager::ProjectWorkPlanner.new(**params).call)
  end

  no_commands do
    def work_in_progress
      puts "WARNING! This functionality is not fully implemented yet."
    end
  end
end
