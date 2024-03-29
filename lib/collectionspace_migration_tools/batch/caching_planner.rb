# frozen_string_literal: true

module CollectionspaceMigrationTools
  module Batch
    # Takes batch data and derives the set of commands needed to efficiently
    # populate the required caches
    class CachingPlanner
      include Dry::Monads[:result]

      class << self
        def call(...)
          new(...).call
        end
      end

      def initialize(refname:, csid:)
        @refname_deps = refname.sub("vocabularies", "vocabulary").split("|")
        @csid_deps = csid.split("|")
      end

      def call
        both = refname_deps.intersection(csid_deps)
        csid = csid_deps - both
        refname = refname_deps - both

        result = {}
        result[:populate_both_caches] = both unless both.empty?
        result[:populate_csid_cache] = csid unless csid.empty?
        result[:populate_refname_cache] = refname unless refname.empty?
      rescue => err
        msg = "#{err.message} IN #{err.backtrace[0]}"
        Failure(CMT::Failure.new(context: "#{self.class.name}.#{__callee__}",
          message: msg))
      else
        Success(result)
      end

      private

      attr_reader :refname_deps, :csid_deps
    end
  end
end
