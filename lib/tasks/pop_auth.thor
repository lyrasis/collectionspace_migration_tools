# frozen_string_literal: true

require 'dry/monads'
require 'thor'

# tasks targeting CS XML payloads
class Auth < Thor
  include Dry::Monads[:result]
  namespace 'pop:auth'.to_sym

  desc 'one RECTYPE', 'populate caches with refnames and csids for ONE authority record type'
  def one(rectype)
    query = CMT::QueryBuilder::Authority::RecordType.new(rectype).query
    do_one(rectype, query)
    CMT.safe_exit
  end

  desc 'multi', 'populate caches with refnames and csids for list of authority record types'
  def multi
  end

  desc 'all', 'populate caches with refnames and csids for all authority record types'
  def all
    rectypes = CMT::RecordTypes.authority
    queries = rectypes.map do |rectype|
      CMT::QueryBuilder::Authority::RecordType.new(rectype).query
    end
    do_multi(rectypes, queries)
    CMT.safe_exit
  end

  private

  def do_multi(rectypes, queries)
    rectypes.each_with_index do |rectype, i|
      do_one(rectype, queries[i])
    end
  end
  
  def do_one(rectype, query)
    puts "Querying for #{rectype} terms..."
    CMT::Database::ExecuteQuery.call(query).bind do |data|
      puts "Got #{data.num_tuples} #{rectype} results..."
      CMT::Cache::Populate::Refnames::Terms.call(data)
      CMT::Cache::Populate::Csids::Terms.call(data)
    end
  end
end

