# frozen_string_literal: true

require "fileutils"

module CollectionspaceMigrationTools
  module Batch
    module Csv
      # Handles replacing updated batches csv
      class Rewriter
        include Dry::Monads[:result]
        include Dry::Monads::Do.for(:do_rewrite)

        class << self
          def call(table)
            new.call(table)
          end
        end

        attr_reader :status

        def initialize
          @current = CMT.config.client.batch_csv
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
        rescue => err
          msg = "#{err.message} IN #{err.backtrace[0]}"
          Failure(CMT::Failure.new(context: "#{self.class.name}.#{__callee__}",
            message: msg))
        else
          Success()
        end

        def delete_backup
          FileUtils.rm(backup) if File.exist?(backup)
        rescue => err
          msg = "#{err.message} IN #{err.backtrace[0]}"
          Failure(CMT::Failure.new(context: "#{self.class.name}.#{__callee__}",
            message: msg))
        else
          Success()
        end

        def do_rewrite(table)
          _backed_up = yield(backup_old)
          _new_written = yield(write_new(table))
          _backup_removed = yield(delete_backup)

          Success()
        end

        def process_rewrite_failure(failure)
          if failure.context.end_with?("backup_old")
            new_msg = "Could not back up existing batches CSV. Did not not update.\nACTION FOR YOU: none\nError received was:"
            msg = "#{new_msg}\n#{failure.message}"
            @status = Failure(CMT::Failure.new(context: failure.context,
              message: msg))
          elsif failure.context.end_with?("write_new")
            new_msg = "Backed up existing batches CSV. Update write failed. To protect the data we did not revert to the backup automatically.\nACTION FOR YOU: Manually verify the existing file was not rewritten or corrupted, and delete the backup.\nError received was:"
            msg = "#{new_msg}\n#{failure.message}"
            @status = Failure(CMT::Failure.new(context: failure.context,
              message: msg))
          elsif failure.context.end_with?("write_new")
            warn("Batches csv successfully updated, but we could not delete the backup. You may wish to manually delete it.")
          end

          status
        end

        def write_new(table)
          File.open(current, "w") { |file| file << table.to_csv }
        rescue => err
          msg = "#{err.message} IN #{err.backtrace[0]}"
          Failure(CMT::Failure.new(context: "#{self.class.name}.#{__callee__}",
            message: msg))
        else
          Success()
        end
      end
    end
  end
end
