# frozen_string_literal: true

module CollectionspaceMigrationTools
  module Duplicate
    class Checker
      include Dry::Monads[:result]
      include Dry::Monads::Do.for(:call)

      attr_reader :rectype

      class << self
        def call(...)
          new(...).call
        end
      end

      def initialize(rectype:)
        @rectype = rectype
      end

      def call
        obj = yield(CMT::RecordTypes.to_obj(rectype))
        unless obj.respond_to?(:duplicates)
          errmsg = "#{rectype} is not duplicate-checkable"
          puts errmsg
          return Failure(errmsg)
        end

        results = yield(obj.duplicates)
        puts "#{results.num_tuples} duplicates"

        Success(results)
      end

      def to_monad = Success(self)
    end
  end
end
