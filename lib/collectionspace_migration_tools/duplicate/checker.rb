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

      # @param rectype [String]
      # @param mode [:single, :all]
      def initialize(rectype:, mode: :single)
        @rectype = rectype
        @mode = mode
      end

      def call
        obj = yield(CMT::RecordTypes.to_obj(rectype))
        unless obj.respond_to?(check_method)
          errmsg = "#{rectype} is not duplicate-checkable"
          puts errmsg
          return Failure(errmsg)
        end

        results = yield(obj.send(check_method))
        puts "#{results.num_tuples} duplicates"

        Success(results)
      end

      def to_monad = Success(self)

      private

      attr_reader :mode

      def check_method = (mode == :single) ? :duplicates : :all_duplicates
    end
  end
end
