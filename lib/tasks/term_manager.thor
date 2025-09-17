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
  option :mode, required: false, type: :string, enum: %w[force_current],
    aliases: "-m"
  def work_plan
    work_in_progress
    params = {instances: options[:instances],
              term_sources: options[:term_sources]}.compact
    project = CMT::TermManager::Project.new(options[:project], **params)
    result = CMT::TermManager::ProjectWorkPlanner.new(
      project, options[:mode]&.to_sym
    ).call
    pp(result)
  end

  desc "run", "Run TermManager project"
  option :project, required: true, type: :string, aliases: "-p"
  option :instances, required: false, type: :array, aliases: "-i"
  option :term_sources, required: false, type: :array, aliases: "-s"
  option :mode, required: false, type: :string, enum: %w[force_current],
    aliases: "-m"
  def run
    work_in_progress

    params = {instances: options[:instances],
              term_sources: options[:term_sources]}.compact
    p = CMT::TermManager::Project.new(options[:project], **params)
    CMT::TermManager::ProjectWorkRunner.new(p, options[:mode]&.to_sym).call
  end

  desc "reset_exact_term_lists", "Delete term list terms not in source file(s)"
  long_desc "Runs for all vocabularies listed in `term_list_sources`. "\
    "Runs only on dynamic term list vocabularies whose "\
    "`initial_term_list_load_mode`=exact."
  option :project, required: true, type: :string, aliases: "-p"
  option :instances, required: false, type: :array, aliases: "-i"
  def reset_exact_term_lists
    work_in_progress

    params = {instances: options[:instances]}.compact
    p = CMT::TermManager::Project.new(options[:project], **params)
    CMT::TermManager::TermListResetter.new(p).call
  end

  no_commands do
    def work_in_progress
      puts "WARNING! This functionality is not fully implemented yet. \n"\
        "- Does NOT handle dynamic term list updates\n"\
        "- Does NOT handle authority updates where primary "\
        "termDisplayName value is changed\n"\
        "- Does not handle subsequent authority loads via API only"
    end
  end
end
