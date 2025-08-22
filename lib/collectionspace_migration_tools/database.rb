# frozen_string_literal: true

module CollectionspaceMigrationTools
  # Namespace shared data holder for database connection
  module Database
    ::CMT::DB = CollectionspaceMigrationTools::Database

    module_function

    # @param tenant_name [nil, String]
    # @return [String]
    def tunnel_command(tenant_name = nil)
      name = tenant_name || CMT.config.client.tenant_name
      tenant = CHIA.tenant_for(name)

      tenant.db_tunnel_command(
        CMT.config.system.bastion_user,
        CMT.config.system.db_port
      )
    end
  end
end
