# frozen_string_literal: true

module CollectionspaceMigrationTools
  module Batch
    extend Dry::Monads[:result, :do]
    
    class << self
      def delete(id)
        batch = yield(find(id))
        _deleted = yield(batch.delete)

        Success()
      end

      def dir(id)
        batch = yield(find(id))

        Success(batch.dir)
      end

      def find(id)
        csv = yield(CMT::Batch::Csv::Reader.new)
        batch = yield(CMT::Batch::Batch.new(csv, id))

        Success(batch)
      end

      def map(id, autocache, clearcache)
        _run = yield(CMT::Batch::MapRunner.call(
          batch: id, autocache: autocache, clearcache: clearcache
        ))
        
        Success()
      end
    end
  end
end
