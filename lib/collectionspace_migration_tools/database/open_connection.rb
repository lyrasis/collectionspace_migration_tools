# frozen_string_literal: true

require 'dry/monads'
require 'pg'

module CollectionspaceMigrationTools
  module Database
    class PG::Connection
      def close
        if open?
          finish
          puts 'Closed DB connection'
        else
          puts 'DB connection already closed'
        end
        CMT.tunnel.close
      end
      
      def open?
        status
      rescue PG::ConnectionBad
        false
      else
        true
      end
    end
    
    # opens database connection through tunnel
    class OpenConnection
      class << self
        include Dry::Monads[:result]

        def call
          check_connection = CMT.connection

          if check_connection && check_connection.open?
            puts 'DB connection already open. Using existing.'
            Success(check_connection)
          else
            CMT::DB::OpenTunnel.call.bind do
              get_connection
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

        def get_connection
          sleep(3)
          connection = PG::Connection.new(**db_info)
        rescue StandardError => err
          Failure(CMT::Failure.new(context: "#{name}.#{__callee__}", message: err.message))
        else
          CMT.connection = connection
          Success(connection)
        end
      end
    end
  end
end
