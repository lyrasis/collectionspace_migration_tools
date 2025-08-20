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
    params = {instances: options[:instances],
              term_sources: options[:term_sources]}.compact
    project = CMT::TermManager::Project.new(options[:project], **params)
    pp(CMT::TermManager::ProjectWorkPlanner.new(project).call)
  end

  desc "run", "Run TermManager project"
  option :project, required: true, type: :string, aliases: "-p"
  option :instances, required: false, type: :array, aliases: "-i"
  option :term_sources, required: false, type: :array, aliases: "-s"
  def run
    work_in_progress

    params = {instances: options[:instances],
              term_sources: options[:term_sources]}.compact
    p = CMT::TermManager::Project.new(options[:project], **params)
    CMT::TermManager::ProjectWorkRunner.new(p).call
  end

  no_commands do
    def work_in_progress
      puts "WARNING! This functionality is not fully implemented yet. \n"\
        "- Only handles dynamic term list adds and deletes\n"\
        "- Does NOT handle authorities yet\n"\
        "- Does not yet add updated lines to version log"
    end
  end
end
