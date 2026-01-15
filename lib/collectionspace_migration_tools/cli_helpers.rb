# frozen_string_literal: true

module CollectionspaceMigrationTools
  module CliHelpers
    ::CMT::CliHelpers = CollectionspaceMigrationTools::CliHelpers

    module_function

    def db_disconnect
      CMT.connection&.close
      CMT.tunnel&.close
    end

    def safe_db
      yield
    rescue => err
      raise err if options[:debug]
      warn err.message
      db_disconnect
      exit(1)
    else
      db_disconnect
      exit(0)
    end
  end
end
