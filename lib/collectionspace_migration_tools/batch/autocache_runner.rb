# frozen_string_literal: true

module CollectionspaceMigrationTools
  module Batch
    # Sets up and runs autocaching for a batch
    class AutocacheRunner
      include Dry::Monads[:result]
      include Dry::Monads::Do.for(:call)

      class << self
        def call(...)
          new(...).call
        end
      end

      # @param batch [CMT::Batch::Batch]
      def initialize(batch)
        @batch = batch
      end

      def call
        path = batch.source_csv
        mapper = yield CMT::Parse::RecordMapper.call(batch.mappable_rectype)
        csid_deps = yield CMT::Batch::CsidCacheDependencyIdentifier.call(
          path: path,
          mapper: mapper
        )

        first_row = yield CMT::Csv::FirstRowGetter.call(path)
        rn_deps = yield CMT::Batch::RefnameCacheDependencyIdentifier.call(
          headers: first_row.headers,
          mapper: mapper
        )

        plan = yield CMT::Batch::CachingPlanner.call(
          refname: rn_deps,
          csid: csid_deps
        )
        _run = yield(CMT::Batch::AutoCacher.call(plan))

        Success()
      end

      private

      attr_reader :batch
    end
  end
end
