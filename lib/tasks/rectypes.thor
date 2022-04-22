# frozen_string_literal: true

require 'thor'

# tasks for listing record types for reference
class Rectypes < Thor
  namespace :rt
  
  desc 'all', 'list all cacheable/mappable rectypes'
  def all
    puts CMT::RecordTypes.mappable
    exit(0)
  end

  desc 'auth', 'list all cacheable/mappable authority rectypes'
  def auth
    puts CMT::RecordTypes.authorities
    exit(0)
  end

  desc 'obj', 'list all cacheable/mappable object rectype value'
  def obj
    puts CMT::RecordTypes.object
    exit(0)
  end

  desc 'procs', 'list all cacheable/mappable procedure rectypes'
  def procs
    puts CMT::RecordTypes.procedures
    exit(0)
  end

  desc 'rels', 'list all cacheable/mappable relationship rectypes'
  def rels
    puts CMT::RecordTypes.relations
    exit(0)
  end
end

