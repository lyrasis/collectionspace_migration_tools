# frozen_string_literal: true

module CollectionspaceMigrationTools
  module Batch
    extend Dry::Monads[:result, :do]
    
    module_function
    def delete(id)
      batch = yield(find(id))
      _deleted = yield(batch.delete)

      Success()
    end

    def dir(id)
      batch = yield(find(id))

      Success(batch.dir)
    end

    def done(id)
      batch = yield(find(id))
      _rewritten = yield(batch.mark_done)
      
      Success()
    end

    def find(id)
      csv = yield(CMT::Batch::Csv::Reader.new)
      batch = yield(CMT::Batch::Batch.new(csv, id))

      Success(batch)
    end

    def map(id, autocache, clearcache)
      _run = yield(CMT::Batch::MapRunner.call(
        batch_id: id, autocache: autocache, clearcache: clearcache
      ))
      
      Success()
    end

    def prep_missing_terms(id)
      _split = yield(CMT::Batch::MissingTerms::ReportSplitter.call(batch_id: id))
      batches = yield(CMT::Batch::MissingTerms::BatchCreator.call(batch_id: id))

      Success(batches)
    end
    
    def rollback_ingest(id)
      batch = yield(find(id))
      rolled_back = yield(batch.rollback_ingest)

      Success(rolled_back)
    end

    def rollback_map(id)
      batch = yield(find(id))
      rolled_back = yield(batch.rollback_map)

      Success(rolled_back)
    end
    
    def rollback_upload(id)
      batch = yield(find(id))
      rolled_back = yield(batch.rollback_upload)

      Success(rolled_back)
    end
  end
end

