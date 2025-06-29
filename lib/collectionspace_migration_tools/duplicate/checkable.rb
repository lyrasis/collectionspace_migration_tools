# frozen_string_literal: true

module CollectionspaceMigrationTools
  module Duplicate
    # mixin module with cache population
    #
    # Classes mixing this in need to have the following methods:
    #   - cacheable_data_query
    #   - name
    #   - rectype_mixin
    #   - to_monad
    #   - to_s
    module Checkable
      include Dry::Monads[:result]
      include Dry::Monads::Do.for(:duplicates)

      def duplicates
        _status = yield(self)
        query = yield(duplicates_query)

        puts "\nQuerying for #{name} duplicates..."
        rows = yield(CMT::Database::ExecuteQuery.call(query))
        CMT.connection&.close
        CMT.tunnel&.close

        Success(rows)
      end
    end
  end
end
