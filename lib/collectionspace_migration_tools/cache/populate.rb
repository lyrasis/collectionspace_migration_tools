# frozen_string_literal: true

require 'benchmark'
require 'benchmark-memory'
require 'collectionspace/client'
require 'dry/monads'
require 'time_up'

module CollectionspaceMigrationTools
  module Cache
    # populates RefCache
    class Populate
      include Dry::Monads[:result]

      class << self
        def call(query)
          self.new(query)
        end
      end

      attr_reader :errors, :result
      
      def initialize(query)
        @errors = []
        call(query)
      end
      
      def call(query)
        CMT::DB::ExecuteQuery.call(query).bind do |result|
          @result = result
          CMT::RefCache.call.bind do |cache|
            populate_cache(cache: cache, refnames: result.values.flatten)
          end
        end
      end


      def clean_refnames(parsed_results)
        by_class = parsed_results.group_by{ |result| result.class }
        errors = by_class[Object.const_get('String')]
        @errors = errors if errors
        by_class[Object.const_get('CollectionSpace::RefName')]
      end

      def parse_refnames(refnames)
        refnames.map do |refname|
          CollectionSpace::RefName.new(refname)
        rescue StandardError
          refname
        end
      end

      def parse_refname(refname)
          CollectionSpace::RefName.new(refname)
        rescue StandardError
          refname
      end

      def prep(refname)
        sig = %i[type subtype label].map{ |key| refname.method(key).call }
        sig << refname.instance_variable_get(:@refname)
        sig
      end

      def iterative_population(cache:, refnames:)
        cache.reset
        puts "CACHE RESET: #{cache.size}"
        parsed = parse_refnames(refnames)
        cleaned = clean_refnames(parsed)
        prepped = cleaned.map{ |refname_obj| prep(refname_obj) }
        put(prepped, cache)
        puts "CACHE SIZE: #{cache.size}"
      end

      def chained_population(cache:, refnames:)
        cache.reset
        puts "CACHE RESET: #{cache.size}"
        prepped = parse_refnames(refnames)
        cleaned = clean_refnames(parsed)
        prepped = cleaned.map{ |refname_obj| prep(refname_obj) }
        put(prepped, cache)
        puts "CACHE SIZE: #{cache.size}"
      end

      def one_iteration_population(cache:, refnames:)
        cache.reset
        puts "CACHE RESET: #{cache.size}"
        refnames.each do |refname|
          parsed = parse_refname(refname)
          if parsed.is_a?(String)
            @errors << parsed
            next
          end

          sig = %i[type subtype label].map{ |key| parsed.method(key).call }
          sig << refname
          cache.put(*sig)
        end
        puts "CACHE SIZE: #{cache.size}"
      end
      
      def put(refnames, cache)
        refnames.each{ |refname| cache.put(*refname) }
      end
      
      def populate_cache(cache:, refnames:)
        puts "Populating cache with #{refnames.length} refnames..."
        Benchmark.bmbm do |x|
          x.report('Time:Iterative'){ iterative_population(cache: cache, refnames: refnames) }
          x.report('Time:One'){ one_iteration_population(cache: cache, refnames: refnames) }
        end

        Benchmark.memory do |x|
          x.report('Memory:Iterative'){ iterative_population(cache: cache, refnames: refnames) }
          x.report('Memory:One'){ one_iteration_population(cache: cache, refnames: refnames) }
        end


        # if errors.empty?
        #   Success(cache)
        # else
        #   Failure(CMT::Failure.new(context: 'CollectionSpace::RefName.new', message: errors))
        # end
      end
    end
  end
end



