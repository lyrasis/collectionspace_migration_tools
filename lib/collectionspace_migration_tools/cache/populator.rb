# frozen_string_literal: true

require "dry/monads"

module CollectionspaceMigrationTools
  module Cache
    class Populator
      include Dry::Monads[:result]

      class << self
        def call(cache_type:, rec_type:, data:)
          new(cache_type: cache_type, rec_type: rec_type).call(data)
        end
      end

      def initialize(cache_type:, rec_type:)
        @cache_type = cache_type
        @cache = CMT.send("#{cache_type}_cache".to_sym)
        @redis = cache.instance_variable_get(:@cache)
          .instance_variable_get(:@c)
        @cache_name = cache_type.upcase
        @rec_type = rec_type
        extend record_type_mixin
      end

      def call(data)
        before_report(data)
        do_population(data).either(
          ->(result) {
            after_report
            Success()
          },
          ->(result) {
            problem_report(result)
            Failure(result)
          }
        )
      end

      private

      attr_reader :cache_type, :cache, :redis, :cache_name, :rec_type

      def before_report(data)
        puts "Populating #{cache_name} cache (current size: #{cache.size}) "\
          "with #{data.num_tuples} keys..."
      end

      def after_report
        puts "#{cache_name} populated. Resulting size: #{cache.size}"
        Success("ok")
      end

      def do_population(data)
        redis.pipelined do |pipeline|
          data.each { |row| pipeline.set(*key_val(row)) }
        end
      rescue => err
        Failure(
          CMT::Failure.new(context: "#{name}.#{__callee__}",
            message: err.message)
        )
      else
        Success("ok")
      end

      def problem_report(failure)
        puts "Problem populating #{cache_name} cache..."
        puts failure
        Failure(failure)
      end

      def record_type_mixin
        modname = "CollectionspaceMigrationTools::Cache::Populate::Types::"\
          "#{rec_type}"
        modname.split("::").reduce(Module, :const_get)
      end
    end
  end
end
