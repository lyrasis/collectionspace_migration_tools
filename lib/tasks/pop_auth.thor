# frozen_string_literal: true

require 'thor'

# tasks targeting CS XML payloads
class Auth < Thor
  include CMT::CliHelpers
  namespace 'pop:auth'.to_sym

  desc 'one RECTYPE', 'populate caches with refnames and csids for ONE authority record type'
  def one(rectype)
    invoke 'pop:auth:list', [], rectypes: [rectype]
  end

  option :rectypes, :type => :array
  desc 'list --rectypes place work', 'populate caches with refnames and csids for list of authority record types'
  def list
    rectypes = options[:rectypes]
    queries = get_queries(rectypes)
    query_and_populate(rectypes, queries, 'AuthTerms')
    CMT.safe_exit
  end

  desc 'all', 'populate caches with refnames and csids for all authority record types'
  def all
    invoke 'pop:auth:list', [], rectypes: CMT::RecordTypes.authority
  end

  private
  
  def get_queries(rectypes)
    rectypes.map do |rectype|
      CMT::QueryBuilder::Authority.call(rectype)
    end
  end
end

