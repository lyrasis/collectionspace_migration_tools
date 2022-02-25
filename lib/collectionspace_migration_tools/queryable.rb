# frozen_string_literal: true

require 'collectionspace/client'

module CollectionspaceMigrationTools
  module Queryable

    module_function

    def do_one(rectype, query)
      puts "Querying for #{rectype} terms..."
      CMT::Database::ExecuteQuery.call(query).bind do |data|
        puts "Got #{data.num_tuples} #{rectype} results..."
        CMT::Cache::Populate::Refnames::Terms.call(data)
        CMT::Cache::Populate::Csids::Terms.call(data)
      end
    end
  end
end
