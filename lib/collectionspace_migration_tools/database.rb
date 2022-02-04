# frozen_string_literal: true

module CollectionspaceMigrationTools
  # Namespace shared data holder for database connection
  module Database
    ::CMT::DB = CollectionspaceMigrationTools::Database

    module_function

    def close_tunnel(tunnel_pid)
      Process.kill('HUP', tunnel_pid)
    end
  end
end
