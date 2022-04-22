# frozen_string_literal: true

module CollectionspaceMigrationTools
  module Batches
    extend Dry::Monads[:result, :do]
    
    module_function

    # @param status [Symbol] :mappable?, :uploadable?, :ingestable?, :is_done?
    # @returns Dry::Monad::Result wrapping array of Batch::Batch objects
    def by_status(status)
      CMT::Batch::Csv::Reader.new.find_status(status)
    end

    # @param status [Symbol] :mappable?, :uploadable?, :ingestable?, :is_done?
    # @returns [Array<String>] ids of batches matching status
    def ids_by_status(status)
      batches = yield(CMT::Batch::Csv::Reader.new.find_status(status))
      ids = batches.map(&:id)

      Success(ids)
    end

    def map(autocache = CMT.config.client.auto_refresh_cache_before_mapping,
            clearcache = CMT.config.client.clear_cache_before_refresh)
      ids = yield(ids_by_status(:mappable?))
      results = ids.map{ |id| CMT::Batch.map(id, autocache, clearcache) }
      _chk = yield(result_check(results))

      Success()
    end

    def result_check(results)
      failures = results.select(&:failure?)
      return Success() if failures.empty?

      Failure(failures)
    end
  end
end

