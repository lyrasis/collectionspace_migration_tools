# frozen_string_literal: true

module CollectionspaceMigrationTools
  # Namespace and alias for code used/reused by Thor CLI commands
  #   in ./lib/tasks
  module CliHelpers
    ::CMT::CliHelpers = CollectionspaceMigrationTools::CliHelpers
  end
end
