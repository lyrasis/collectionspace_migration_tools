# frozen_string_literal: true

module CollectionspaceMigrationTools
  module Cache
    # mixin module with cache population
    #
    # Classes mixing this in need to have the following methods:
    #   - cacheable_data_query
    #   - rectype_mixin
    #   - to_monad
    #   - to_s
    module Populatable
      include Dry::Monads[:result]
      include Dry::Monads::Do.for(:populate_both_caches, :populate_cache)
      
      def populate_both_caches
        _status = yield(self)
        query = yield(cacheable_data_query)

        puts "\n\nQuerying cacheable data for #{to_s}..."
        rows = yield(CMT::Database::ExecuteQuery.call(query))

        ct = result_count(rows)
        return Success() if ct == 0

        threads = []
        %w[refname csid].each do |cache_type|
          threads << Thread.new{ CMT::Cache::Populator.call(cache_type: cache_type, rec_type: rectype_mixin, data: rows) }
        end
        threads.each{ |thread| thread.join }

        Success()
      end

      def populate_csid_cache
        populate_cache('csid')
      end

      def populate_refname_cache
        populate_cache('refname')
      end
      
      def populate_cache(type)
        _status = yield(self)
        query = yield(cacheable_data_query)

        puts "Querying cacheable data for #{to_s}..."
        rows = yield(CMT::Database::ExecuteQuery.call(query))

        ct = result_count(rows)
        return Success() if ct == 0

        CMT::Cache::Populator.call(cache_type: type, rec_type: rectype_mixin, data: rows)

        Success()
      end

      # @param rows [PG::Result]
      def result_count(rows)
        result_size = rows.num_tuples
        puts "Got #{result_size} results..."
        result_size
      end
    end
  end
end
