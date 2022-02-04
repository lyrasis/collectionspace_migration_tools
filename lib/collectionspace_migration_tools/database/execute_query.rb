# frozen_string_literal: true

require 'dry/monads'

module CollectionspaceMigrationTools
  module Database
    # Executes query and returns result if successful
    class ExecuteQuery
      class << self
        include Dry::Monads[:result]

        def call(db:, sql:)
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
