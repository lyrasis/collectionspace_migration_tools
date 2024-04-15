# frozen_string_literal: true

require "csv"

module CollectionspaceMigrationTools
  module ArchiveCsv
    class Archiver
      include Dry::Monads[:result]
      include Dry::Monads::Do.for(:call)

      class << self
        def call(...)
          new.call(...)
        end
      end

      def initialize(
        path: CMT::ArchiveCsv.path,
        headers: CMT::Batch::Csv::Headers.all_headers
      )
        @path = path
        @headers = headers
      end

      # @param batch[CMT::Batch::Batch]
      def call(batch)
        _present = if CMT::ArchiveCsv.present?
          yield CMT::ArchiveCsv.file_check
        else
          yield CMT::ArchiveCsv::Creator.call
        end
        _write = yield write_row(batch)

        Success(batch)
      end

      private

      attr_reader :path, :headers

      def write_row(batch)
        CSV.open(path, "a", headers: true) do |csv|
          csv << headers.map { |hdr| batch.send(hdr.to_sym) }
        end
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
