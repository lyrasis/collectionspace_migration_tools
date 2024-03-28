# frozen_string_literal: true

module CollectionspaceMigrationTools
  # Namespace for the batch archive CSV, if enabled in client config.
  #
  # The archive CSV contains data from the batches CSV for batches deleted after
  # completed ingest (with or without errors). Rows for batches deleted at an
  # earlier workflow stage are not added to the archive CSV.
  module ArchiveCsv
    extend Dry::Monads[:result, :do]

    module_function

    # @return [String]
    def path
      File.join(CMT.config.client.base_dir,
                CMT.config.client.batch_archive_filename)
    end

    # @return [Boolean]
    def present? = File.exist?(path)

    def file_check
      case present?
      when true
        Success()
      when false
        Failure(file_check_failure_msg)
      end
    end

    def parse
      data = File.read(path)
      table = CSV.parse(data, headers: true)
    rescue => err
      msg = "#{err.message} IN #{err.backtrace[0]}"
      Failure(CMT::Failure.new(context: "#{self.class.name}.#{__callee__}",
                               message: msg))
    else
      Success(table)
    end

    def file_check_failure_msg = "No archives CSV file present"
  end
end
