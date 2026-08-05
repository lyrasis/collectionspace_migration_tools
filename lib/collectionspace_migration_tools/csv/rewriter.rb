# frozen_string_literal: true

require "fileutils"

module CollectionspaceMigrationTools
  module Csv
    # Handles replacing updated batches or archives csv
    class Rewriter
      include Dry::Monads[:result]
      include Dry::Monads::Do.for(:do_rewrite)

      class << self
        def call(path, table)
          new(path).call(table)
        end
      end

      attr_reader :status

      def initialize(path)
        @current = path
        @backup = "#{current}.bak"
        @status = Success()
      end

      # @param table [CSV::Table]
      def call(table)
        do_rewrite(table).either(
          ->(success) { status },
          ->(failure) { process_rewrite_failure(failure) }
        )
      end

      def to_monad
        status
      end

      private

      attr_reader :table, :current, :backup

      def backup_old
        FileUtils.cp(current, backup)

        Success()
      rescue => err
        Failure(err.message)
      end

      def delete_backup
        FileUtils.rm(backup) if File.exist?(backup)

        Success()
      rescue => err
        Failure(err.message)
      end

      def do_rewrite(table)
        _backed_up = yield(backup_old)
        _new_written = yield(write_new(table))
        _backup_removed = yield(delete_backup)

        Success()
      end

      def process_rewrite_failure(failure)
        if failure.end_with?("backup_old")
          @status = Failure("Could not back up existing batches CSV. Did not "\
                            "update.\nACTION FOR YOU: none\n"\
                            "Error received was:\n#{failure}")
        elsif failure.end_with?("write_new")
          @status = Failure("Backed up existing batches CSV. Update write "\
                            "failed. To protect the data we did not revert "\
                            "to the backup automatically.\n"\
            "ACTION FOR YOU: Manually verify the existing file was not "\
            "rewritten or corrupted, and delete the backup.\n"\
            "Error received was:\n#{failure}")
        else
          warn("Batches csv successfully updated, but we could not delete the "\
               "backup. You may wish to manually delete it.")
        end

        status
      end

      def write_new(table)
        File.open(current, "w") { |file| file << table.to_csv }

        Success()
      rescue => err
        Failure(err.message)
      end
    end
  end
end
