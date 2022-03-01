# frozen_string_literal: true

require 'bundler/setup'
require_relative '../lib/collectionspace_migration_tools'
require 'benchmark'
require 'debug'

query = CMT::QueryBuilder::Authority.call('person')
result = CMT::Database::ExecuteQuery.call(query)
data = result.success? ? result.value! : nil
CMT.connection.close
CMT.tunnel.close

unless data
  puts "Query failed. Cannot proceed."
  exit
end

def clear_caches
  [CMT.csid_cache, CMT.refname_cache].each{ |cache| cache.flush }
end

def pop_serial(data)  
  CMT::CliHelpers.populate_caches_serial('AuthTerms', data)
  clear_caches
end

def pop_thread(data)
  CMT::CliHelpers.populate_caches_threaded('AuthTerms', data)
  clear_caches
end



clear_caches

Benchmark.bm do |x|
  x.report('serial'){ 10.times{ pop_serial(data) } }
  x.report('thread'){ 10.times{ pop_thread(data) } }
end
