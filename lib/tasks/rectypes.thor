# frozen_string_literal: true

require 'thor'

# tasks for listing record types for reference
class Rectypes < Thor
  namespace :rt

  include Dry::Monads[:result]
  include Dry::Monads::Do.for(:check_is_deleteable, :do_delete_all)

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

  desc 'delete_all RECTYPE', 'deletes all records of a given mappable rectype'
  long_desc <<-LONGDESC
    Currently only implemented for collection object, procedure, and authority
    rectypes. Nonhierarchical relationships between deleted objects/procedures
    and other things get deleted. If there are many nonhierarchical
    relationships, these deletions can be quite slow. Authority terms in
    hierarchical relationships or used in records will not be deleted.
  LONGDESC
  def delete_all(rectype)
    do_delete_all(rectype).either(
      ->(success){ exit(0) },
      ->(failure){ puts failure.to_s; exit(1) }
    )
  end

  no_commands do
    def check_is_deleteable(rectype)
      obj = yield CMT::RecordTypes.to_obj(rectype)
      msg = "Deletion of all #{rectype} records is not yet implemented"
      return Failure(msg) unless obj.respond_to?(:delete_all)

      Success(obj)
    end

    def do_delete_all(rectype)
      obj = yield check_is_deleteable(rectype)
      deleter = yield obj.delete_all
    end
  end
end
