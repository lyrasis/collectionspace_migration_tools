# frozen_string_literal: true

# @todo speed up by threading single cache population calls
module CollectionspaceMigrationTools
  module Batch
    # Populates cache(s) based on instructions in CachingPlanner output
    class AutoCacher
      include Dry::Monads[:result]
      include Dry::Monads::Do.for(:do_caching)

      class << self
        def call(...)
          new(...).call
        end
      end

      def initialize(plan)
        @plan = plan
        @results = []
      end

      def call
        puts "\n\nAUTO-CACHING"
        starttime = Time.now

        plan.each { |meth, list| do_command(meth, list) }

        CMT.connection.close
        CMT.tunnel.close

        puts "Elapsed time for caching: #{Time.now - starttime}"
        return Success() unless @results.any?(:failure?)

        Failure("#{self.class.name} ERROR: Unable to cache some necessary values")
      end

      def to_monad
      end

      private

      attr_reader :plan

      def do_caching(rectype, meth)
        obj = yield(CMT::RecordTypes.to_obj(rectype))
        _result = yield(obj.send(meth))

        Success()
      end

      def do_command(meth, list)
        list.each do |rectype|
          @results << do_caching(rectype, meth)
        end
      end
    end
  end
end
