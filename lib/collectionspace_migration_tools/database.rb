# frozen_string_literal: true

module CollectionspaceMigrationTools
  # Namespace shared data holder for database connection
  module Database
    ::CMT::DB = CollectionspaceMigrationTools::Database

    module_function

    def tunnel_command
      tenant = CHIA.tenant_for(CMT.config.client.tenant_name)

      tenant.db_tunnel_command(
        CMT.config.system.bastion_user,
        CMT.config.system.db_port
      )
    end
  end
end
