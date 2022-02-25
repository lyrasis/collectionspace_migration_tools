# frozen_string_literal: true

require 'dry/monads'

module CollectionspaceMigrationTools
  module Database
    # Executes query and returns result if successful
    class ExecuteQuery
      class << self
        include Dry::Monads[:result]

        def call(query)
          CMT::Database::OpenConnection.call.bind do |db|            
            execute_query(db, query)
          end
        end

        private

        def execute_query(db, query)
          result = db.exec(query)
        rescue StandardError => err
          Failure(CMT::Failure.new(context: "#{name}.#{__callee__}", message: err.message))
        else
          Success(result)
        end
      end
    end
  end
end
