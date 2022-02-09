# frozen_string_literal: true

require 'dry/monads'

module CollectionspaceMigrationTools
  module Database
    # Executes query and returns result if successful
    class ExecuteQuery
      class << self
        include Dry::Monads[:result]

        def call(query)
          CMT::DB::OpenConnection.call.bind do |connection|
            execute_query(connection.db, query).fmap do |result|
              CMT::DB::CloseConnection.call(connection)
              result
            end
          end
        end

        private
        
        def execute_query(db, sql)
          result = db.exec(sql)
        rescue StandardError => err
          Failure(CMT::Failure.new(context: "#{name}.#{__callee__}", message: err.message))
        else
          Success(result)
        end
      end
    end
  end
end
