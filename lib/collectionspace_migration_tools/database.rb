# frozen_string_literal: true

module CollectionspaceMigrationTools
  # Namespace shared data holder for database connection
  module Database
    ::CMT::DB = CollectionspaceMigrationTools::Database

    module_function

    # @param tenant [CHIA::Tenant, String]
    # @return [String]
    def db_credentials_for(tenant)
      return extract_db_credentials(tenant) if tenant.respond_to?(:db_host)

      t = CHIA.tenant_for(tenant)
      extract_db_credentials(t)
    end

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

    # @param tenant [CHIA::Tenant]
    def extract_db_credentials(tenant)
      {
        db_host: tenant.db_host,
        db_username: tenant.db_user_name,
        db_password: tenant.db_password,
        db_name: tenant.db_name
      }
    end
  end
end
