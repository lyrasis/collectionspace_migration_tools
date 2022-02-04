# frozen_string_literal: true

module CollectionspaceMigrationTools
  module Database
    # Value object to pass database connection and tunnel pid around together
    class Connection
      attr_reader :db, :tunnel

      def initialize(db:, tunnel:)
        @db = db
        @tunnel = tunnel
      end
    end
  end
end
