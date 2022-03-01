# frozen_string_literal: true

require 'thor'

# tasks populating caches with object/procedure data
class Procedure < Thor
  include CMT::CliHelpers
  namespace 'pop:proc'.to_sym
  desc 'one RECTYPE', 'populate CSID cache for ONE procedure record type'
  def one(rectype)
    invoke 'pop:proc:list', [], rectypes: [rectype]
  end

  option :rectypes, :type => :array
  desc 'list --rectypes place work', 'populate CSID cache with for list of procedure record types'
  def list
    rectypes = options[:rectypes]
    queries = get_queries(rectypes)
    query_and_populate(rectypes, queries, 'Procedures', :csid)
    CMT.safe_exit
  end

  desc 'all', 'populate CSID cache for all procedure record types'
  def all
    invoke 'pop:proc:list', [], rectypes: CMT::RecordTypes.procedures.keys
  end

  private
  
  def get_queries(rectypes)
    rectypes.map do |rectype|
      CMT::QueryBuilder::Procedure.call(rectype)
    end
  end
end

