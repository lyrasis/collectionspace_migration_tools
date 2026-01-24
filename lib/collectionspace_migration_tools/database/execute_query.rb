# frozen_string_literal: true

module CollectionspaceMigrationTools
  module Database
    # Executes query and returns result if successful
    class ExecuteQuery
      extend Dry::Monads[:result, :do]

      class << self
        # @param query [String]
        # @param site_name [nil, String]
        def call(query, site_name = nil)
          db = yield CMT::Database::OpenConnection.call(site_name)
          result = yield execute_query(db, query)

          Success(result)
        end

        private

        def execute_query(db, query)
          result = db.exec(query)
          Success(result)
        rescue => err
          Failure(CMT::Failure.new(context: "#{name}.#{__callee__}",
            message: err.message))
        end
      end
    end
  end
end
