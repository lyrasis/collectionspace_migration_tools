# frozen_string_literal: true

require 'parallel'
require 'smarter_csv'

module CollectionspaceMigrationTools
  module Batch
    class CsidCacheDependencyIdentifier
      include Dry::Monads[:result]
      include Dry::Monads::Do.for(:analyze_authority_hierarchy, :analyze_nonhierarchicalrelationship)
      
      class << self
        def call(...)
          self.new(...).call
        end
      end
      
      def initialize(path:, mapper:)
        @path = path
        @mapper = mapper
        @name = mapper.name
        dependent_setup
      end

      def call
        deps = [mapper.name]
        return Success(deps.first) unless relation?

        case name
        when 'authorityhierarchy'
          analyze_authority_hierarchy
        when 'nonhierarchicalrelationship'
          analyze_nonhierarchicalrelationship
        when 'objecthierarchy'
          deps << 'collectionobject'
          Success(deps.join('|'))
        end

      end

      private

      attr_reader :path, :mapper, :name, :type_lookup, :subtype_lookup

      def analyze_authority_hierarchy
        extracted = yield(extract_authority_hierarchy_rectypes)
        combined = extracted.inject({}, :merge)
        mapped = yield(map_authority_values(combined.keys))

        mapped << name
        
        Success(mapped.sort.join('|'))
      end

      def analyze_nonhierarchicalrelationship
        extracted = yield(extract_nhr_rectypes)
        combined = extracted.inject({}, :merge)
        mapped = yield(map_nhr_values(combined.keys))

        mapped << name
        
        Success(mapped.sort.join('|'))
      end

      def authority_hierarchy_worker(chunk)
        result = {}
        chunk.each{ |row| result["#{row['term_type']}/#{row['term_subtype']}"] = nil }
        result
      end
      
      def chunks
        SmarterCSV.process(
          path, {
            chunk_size: CMT.config.system.csv_chunk_size,
            convert_values_to_numeric: false,
            strings_as_keys: true
          })
      end

      def dependent_setup
        case name
        when 'authorityhierarchy'
          @type_lookup = CMT::RecordTypes.service_path_to_mappable_type_mapping
          @subtype_lookup = CMT::RecordTypes.authority_subtype_machine_to_human_label_mapping
        when 'nonhierarchicalrelationship'
          @type_lookup = CMT::RecordTypes.service_path_to_mappable_type_mapping
        end
      end

      def extract_authority_hierarchy_rectypes
        puts "Analyzing authority_hierarchy source CSV for record types to csid-cache..."
        stime = Time.now
        res = Parallel.map(chunks, in_processes: CMT.config.system.max_threads) do |chunk|
          authority_hierarchy_worker(chunk)
        end
        elapsed = Time.now - stime
        puts "Elapsed time: #{elapsed}"
      rescue StandardError => err
        msg = "#{err.message} IN #{err.backtrace[0]}"
        Failure(CMT::Failure.new(context: "#{self.class.name}.#{__callee__}", message: msg))
      else
        Success(res)
      end

      def extract_nhr_rectypes
        puts "Analyzing nonhierarchicalrelationship source CSV for record types to csid-cache..."
        stime = Time.now
        res = Parallel.map(chunks, in_processes: CMT.config.system.max_threads) do |chunk|
          nhr_worker(chunk)
        end
        elapsed = Time.now - stime
        puts "Elapsed time: #{elapsed}"
      rescue StandardError => err
        msg = "#{err.message} IN #{err.backtrace[0]}"
        Failure(CMT::Failure.new(context: "#{self.class.name}.#{__callee__}", message: msg))
      else
        Success(res)
      end
      
      def map_authority_values(arr)
        res = arr.map do |rectype|
          splitval = rectype.split('/')
          "#{type_lookup[splitval[0]]}-#{subtype_lookup[splitval[1]]}"
        end
      rescue StandardError => err
        msg = "#{err.message} IN #{err.backtrace[0]}"
        Failure(CMT::Failure.new(context: "#{self.class.name}.#{__callee__}", message: msg))
      else
        Success(res)
      end

      def map_nhr_values(arr)
        res = arr.map{ |rectype| type_lookup[rectype] }
      rescue StandardError => err
        msg = "#{err.message} IN #{err.backtrace[0]}"
        Failure(CMT::Failure.new(context: "#{self.class.name}.#{__callee__}", message: msg))
      else
        Success(res)
      end

      def nhr_worker(chunk)
        result = {}
        chunk.each do |row|
          result[row['item1_type']] = nil
          result[row['item2_type']] = nil
        end
        result
      end

      def relation?
        mapper.relation?
      end
    end
  end
end
