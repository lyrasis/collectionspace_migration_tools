# frozen_string_literal: true

module CollectionspaceMigrationTools
  module Caches
    class Clearer
      include Dry::Monads[:result]

      class << self
        def call
          new.call
        end
      end

      def initialize
        @results = []
      end

      def call
        threads = []
        CMT::Caches.types.each do |cache_type|
          threads << Thread.new { clear(cache_type) }
        end
        threads.each { |thread| thread.join }

        @results.each { |result| report(result) }

        if @results.any?(&:failure?)
          Failure(@results)
        else
          Success()
        end
      end

      private

      def clear(cache_type)
        cache = CMT::Caches.get_cache(cache_type)
        cache.flush
      rescue => err
        msg = "#{cache_type.upcase} clear failure: #{err.message} IN #{err.backtrace[0]}"
        @results << Failure(CMT::Failure.new(
          context: "#{self.class.name}.#{__callee__}", message: msg
        ))
      else
        @results << Success("#{cache_type.upcase} cache cleared")
      end

      def report(result)
        result.either(
          ->(success) { puts "Success: #{success}" },
          ->(failure) { puts "Error: #{failure}" }
        )
      end
    end
  end
end
