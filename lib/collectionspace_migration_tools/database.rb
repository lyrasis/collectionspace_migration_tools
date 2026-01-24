# frozen_string_literal: true

module CollectionspaceMigrationTools
  # Namespace shared data holder for database connection
  module Database
    ::CMT::DB = CollectionspaceMigrationTools::Database

    module_function

    # @param site [CHIA::Site, String]
    # @return [String]
    def db_credentials_for(site)
      return extract_db_credentials(site) if site.respond_to?(:db_host)

      t = CHIA.site_for(site)
      extract_db_credentials(t)
    end

    # @param site_name [nil, String]
    # @return [String]
    def tunnel_command(site_name = nil)
      name = site_name || CMT.config.client.site_name
      site = CHIA.site_for(name)

      site.db_tunnel_command(
        CMT.config.system.bastion_user,
        CMT.config.system.db_port
      )
    end

    # @param site [CHIA::Site]
    def extract_db_credentials(site)
      {
        db_host: site.db_host,
        db_username: site.db_user_name,
        db_password: site.db_password,
        db_name: site.db_name
      }
    end
  end
end
