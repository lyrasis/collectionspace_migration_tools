# frozen_string_literal: true

require "pg"

module CollectionspaceMigrationTools
  module Database
    class PG::Connection
      def open?
        status
      rescue PG::ConnectionBad
        false
      else
        true
      end

      def close
        if open?
          dbname = db
          finish
          puts "Closed DB connection to #{dbname}"
        else
          puts "DB connection already closed"
        end
        CMT.tunnel.close
      end
    end

    # opens database connection through tunnel
    class OpenConnection
      extend Dry::Monads[:result, :do]

      class << self
        # @param tenant_name [nil, String]
        def call(tenant_name = nil)
          tenant_name || CMT.config.client.tenant_name
          creds = get_db_info(tenant_name)
          check_connection = CMT.connection

          return new_connection(tenant_name, creds) unless check_connection

          unless check_connection&.open? &&
              check_connection.db == creds[:dbname]
            check_connection.close
            return new_connection(tenant_name, creds)
          end

          Success(check_connection)
        end

        private

        def new_connection(tenant_name, creds)
          _tunnel = yield CMT::DB::OpenTunnel.call(tenant_name)
          result = yield get_connection(creds)

          Success(result)
        end

        def get_db_info(tenant_name)
          return db_info_for_configured_tenant unless tenant_name

          db_info_for_given_tenant(tenant_name)
        end

        def db_info_for_configured_tenant
          {
            host: CMT.config.system.db_connect_host,
            port: CMT.config.system.db_port,
            dbname: CMT.config.client.db_name,
            user: CMT.config.client.db_username,
            password: CMT.config.client.db_password
          }
        end

        def db_info_for_given_tenant(tenant_name)
          creds = CMT::Database.db_credentials_for(tenant_name)

          {
            host: CMT.config.system.db_connect_host,
            port: CMT.config.system.db_port,
            dbname: creds[:db_name],
            user: creds[:db_username],
            password: creds[:db_password]
          }
        end

        def get_connection(creds)
          sleep(3)
          connection = PG::Connection.new(**creds)
          CMT.connection = connection
          puts "New DB connection created for #{connection.db}"
          Success(connection)
        rescue => err
          Failure(CMT::Failure.new(context: "#{name}.#{__callee__}",
            message: err.message))
        end
      end
    end
  end
end
