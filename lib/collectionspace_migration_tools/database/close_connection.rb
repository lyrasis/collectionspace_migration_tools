# frozen_string_literal: true

require 'dry/monads'

module CollectionspaceMigrationTools
  module Database
    # closes database connection and tunnel
    class CloseConnection
      class << self
        include Dry::Monads[:result]
        
        def call(connection)
          db = connection.db
          db.close if db_connected?(db).success?
          CMT::DB::CloseTunnel.call(connection.tunnel)
        end

        private

        def db_connected?(db)
          db.status
        rescue PG::ConnectionBad
          Failure()
        else
          Success()
        end
      end
    end
  end
end
