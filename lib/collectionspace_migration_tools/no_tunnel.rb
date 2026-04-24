# frozen_string_literal: true

module CollectionspaceMigrationTools
  class NoTunnel
    def close = puts ""

    def open? = false

    def status = :closed
  end
end
