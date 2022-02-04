# frozen_string_literal: true

module CollectionspaceMigrationTools
  module Database
    # Closes tunnel process
    class CloseTunnel
      class << self
        def call(tunnel)
          Process.kill('HUP', tunnel)
        end
      end
    end
  end
end

