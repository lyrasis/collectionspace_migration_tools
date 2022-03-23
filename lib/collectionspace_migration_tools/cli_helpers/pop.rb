# frozen_string_literal: true

require 'collectionspace/client'
require 'dry/monads'

module CollectionspaceMigrationTools
  module CliHelpers
    module Pop
      include Dry::Monads[:result]
      
      module_function

      def authorities
        CMT::RecordTypes.authority
      end
      
      def authority_args(rectypes)
        [rectypes, authority_queries(rectypes), 'AuthTerms']
      end
      
      def authority_queries(rectypes)
        rectypes.map do |rectype|
          CMT::QueryBuilder::Authority.call(rectype)
        end
      end

      def procedures
        CMT::RecordTypes.procedures.keys
      end
      
      def procedure_args(rectypes)
        [rectypes, procedure_queries(rectypes), 'Procedures']
      end
      
      def procedure_queries(rectypes)
        rectypes.map do |rectype|
          CMT::QueryBuilder::Procedure.call(rectype)
        end
      end

      def object_args
        [['object'], [CMT::QueryBuilder::Object.call], 'Objects', :csid]
      end

      def relation_args(reltype)
        [["#{reltype} rels"], [CMT::QueryBuilder::Relation.call(reltype)], 'Relations', :csid]
      end

      def vocab_args
        [['vocab'], [CMT::QueryBuilder::Vocabulary.call], 'VocabTerms']
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
          get_query_results(rectype, queries[i]).bind do |rows|
            ct = result_count(rows)
            next if ct == 0

            if cache_type
              populate_single_cache(poptype, rows, cache_type)
            else
              populate_caches(poptype, rows)
            end
          end
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
