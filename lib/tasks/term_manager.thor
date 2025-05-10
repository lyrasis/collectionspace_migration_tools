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

  desc "work_plan", "Display work plan for project"
  option :project, required: true, type: :string, aliases: "-p"
  option :instances, required: false, type: :array, aliases: "-i"
  option :term_sources, required: false, type: :array, aliases: "-s"
  def work_plan
    params = {project: CMT::TermManager::Project.new(options[:project]),
              instances: options[:instances],
              term_sources: options[:term_sources]}.compact
    pp(CMT::TermManager::ProjectWorkPlanner.new(**params).call)
  end
end
