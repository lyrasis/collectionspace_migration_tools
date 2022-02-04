# frozen_string_literal: true

require 'dry/monads'
require 'pg'

module CollectionspaceMigrationTools
  module Database
    # opens database connection through tunnel
    class OpenConnection
      class << self
        include Dry::Monads[:result]

        def call
          CMT::DB::OpenTunnel.call.bind do |tunnel|
            get_connection(tunnel).bind do |connection|
              connection
            end
          end
        end

        private

        def db_info
          {
            host: CMT.config.database.db_connect_host,
            port: CMT.config.database.port,
            dbname: CMT.config.database.db_name,
            user: CMT.config.database.db_user,
            password: CMT.config.database.db_password
          }
        end

        def get_connection(tunnel)
          sleep(3)
          connection = PG::Connection.new(**db_info)
        rescue StandardError => err
          CMT::DB::CloseTunnel.call(tunnel)
          Failure(CMT::Failure.new(context: "#{name}.#{__callee__}", message: err.message))
        else
          Success(CMT::Database::Connection.new(db: connection, tunnel: tunnel))
        end
      end
    end
  end
end
