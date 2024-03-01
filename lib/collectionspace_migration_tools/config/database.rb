# frozen_string_literal: true

module CollectionspaceMigrationTools
  module Config
    class Database < CMT::Config::Section
      def initialize(hash:)
        super
        # If you change default values here, update sample_client_config.yml
        @default_values = {
          port: 5432,
          db_user: "csadmin",
          db_connect_host: "localhost"
        }
        @validator = CMT::Validate::ConfigDatabaseContract
      end
    end
  end
end
