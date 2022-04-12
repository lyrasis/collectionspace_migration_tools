# frozen_string_literal: true

require 'collectionspace/client'

module CollectionspaceMigrationTools
  module CliHelpers
    module Pop
      include Dry::Monads[:result]
      
      module_function

      def authorities
        CMT::RecordTypes.authorities.map{ |str| CMT::Authority.from_str(str) }
      end
      
      def do_population(poptype, rows, cache_type)
        ct = result_count(rows)
        return if ct == 0

        if cache_type
          populate_single_cache(poptype, rows, cache_type)
        else
          populate_caches(poptype, rows)
        end
      end
      
      def procedures
        CMT::RecordTypes.procedures.map{ |str| CMT::Procedure.new(str) }
      end
      
      def object_args
        [['object'], [CMT::QueryBuilder::Object.call], 'Objects', :csid]
      end

      def relation_args(reltype)
        [["#{reltype} rels"], [CMT::QueryBuilder::Relation.call(reltype)], 'Relations', :csid]
      end

      def get_query_results(rectype, query)
        puts "\nQuerying for #{rectype} terms..."
        CMT::Database::ExecuteQuery.call(query)
      end

      def populate_caches(poptype, data)
        threads = []
        %w[refname csid].each do |cache_type|
          threads << Thread.new{ CMT::Cache::Populator.call(cache_type: cache_type, rec_type: poptype, data: data) }
        end
        threads.each{ |thread| thread.join }
      end

      def populate_single_cache(poptype, data, cache_type)
        CMT::Cache::Populator.call(cache_type: cache_type, rec_type: poptype, data: data)
      end

      def query_and_populate(rectypes, queries, poptype, cache_type = nil)
        rectypes.each_with_index do |rectype, i|

          get_query_results(rectype, queries[i]).either(
            ->(rows){ do_population(poptype, rows, cache_type) },
            ->(failure){ puts "QUERY FAILED: #{failure.to_s}" }
          )
        end
      end

      def query_and_populate_new(rectypes, cache_type = nil)
        rectypes.each do |rectype|
          meth = cache_type.nil? ? :populate_both_caches : "populate_#{cache_type}_cache".to_sym
          
          rectype.send(meth).either(
            ->(success){ puts 'ok' },
            ->(failure){ puts "QUERY/POPULATE FAILED FOR #{rectype.to_s.upcase}\n#{failure.to_s}" }
          )
        end
      end

      # @param rows [PG::Result]
      def result_count(rows)
        result_size = rows.num_tuples
        puts "Got #{result_size} results..."
        result_size
      end


      def db_disconnect
        CMT.connection.close
        CMT.tunnel.close
      end
      
      def safe_db
        yield
      rescue StandardError => err
        raise err if options[:debug]
        STDERR.puts err.message
        db_disconnect
      else
        db_disconnect
      end
    end
  end
end
