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
        # @param site_name [nil, String]
        def call(site_name = nil)
          site_name || CMT.config.client.site_name
          creds = get_db_info(site_name)
          check_connection = CMT.connection

          return new_connection(site_name, creds) unless check_connection

          unless check_connection&.open? &&
              check_connection.db == creds[:dbname]
            check_connection.close
            return new_connection(site_name, creds)
          end

          Success(check_connection)
        end

        private

        def new_connection(site_name, creds)
          _tunnel = yield CMT::DB::OpenTunnel.call(site_name)
          result = yield get_connection(creds)

          Success(result)
        end

        def get_db_info(site_name)
          return db_info_for_configured_site unless site_name

          db_info_for_given_site(site_name)
        end

        def db_info_for_configured_site
          {
            host: CMT.config.system.db_connect_host,
            port: CMT.config.system.db_port,
            dbname: CMT.config.client.db_name,
            user: CMT.config.client.db_username,
            password: CMT.config.client.db_password
          }
        end

        def db_info_for_given_site(site_name)
          creds = CMT::Database.db_credentials_for(site_name)

          {
            host: CMT.config.system.db_connect_host,
            port: CMT.config.system.db_port,
            dbname: creds[:db_name],
            user: creds[:db_username],
            password: creds[:db_password]
          }
        end

        def get_connection(creds)
          sleeptime = CMT.config.system.db_tunnel_connection_pause
          sleep(sleeptime)
          connection = PG::Connection.new(**creds)
          CMT.set_connection(connection)
          Success(connection)
        rescue => err
          msg = "#{err.message}\nTRY: increasing system config "\
            "db_tunnel_connection_pause value to greater than "\
            "the current value (#{sleeptime})"
          Failure(CMT::Failure.new(context: "#{name}.#{__callee__}",
            message: msg))
        end
      end
    end
  end
end
