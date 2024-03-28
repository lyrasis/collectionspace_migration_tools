# frozen_string_literal: true

module CollectionspaceMigrationTools
  # Namespace for the batch archive CSV, if enabled in client config.
  #
  # The archive CSV contains data from the batches CSV for batches deleted after
  # completed ingest (with or without errors). Rows for batches deleted at an
  # earlier workflow stage are not added to the archive CSV.
  module ArchiveCsv
    module_function

    # @return [String]
    def path
      File.join(CMT.config.client.base_dir,
                CMT.config.client.batch_archive_filename)
    end

    # @return [Boolean]
    def present? = File.exist?(path)
  end
end
