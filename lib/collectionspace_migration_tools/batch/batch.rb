# frozen_string_literal: true

require "base64"
require "fileutils"

module CollectionspaceMigrationTools
  module Batch
    class Batch
      include Dry::Monads[:result]
      include Dry::Monads::Do.for(:delete, :get_batch_data)
      include CMT::Batch::Mappable
      include CMT::Batch::Uploadable
      include CMT::Batch::Ingestable

      attr_reader :mode

      # @param csv [CMT::Batch::Csv::Reader]
      # @param id [String] batch id
      def initialize(csv, id)
        @csv = csv
        @id = id
        get_batch_data
        @dirpath = "#{CMT.config.client.batch_dir}/#{dir}" if data && dir
      end

      def delete
        _status = yield to_monad
        _del_dir = yield delete_batch_dir
        if CMT.config.client.archive_batches && done?
          _arch = yield CMT::ArchiveCsv::Archiver.call(self)
        end
        _del_row = yield csv.delete_batch(id)

        Success()
      end

      def mappable? = batch_status == "added"
      def uploadable? = batch_status == "mapped"
      def ingestable? = batch_status == "uploaded"
      def done? = batch_status == "ingested"

      def get(field)
        val = send(field.to_sym)
        return Failure("No value for #{field}") if val.nil? || val.empty?

        Success(val)
      end

      # Each header from batches CSV becomes a method name returning the value
      # for this batch
      def method_missing(meth, *args)
        str_meth = meth.to_s
        return data[str_meth] if data.key?(str_meth)

        raise NoMethodError, "You called #{str_meth} with #{args}. This "\
          "method doesn't exist."
      end

      def populate_field(key, value, overwrite: false)
        return Failure("#{key} is not a valid field") unless data.key?(key)

        unless overwrite
          return Failure("#{key} is already populated") unless field_empty?(key)
        end

        data[key] = value
        Success(data)
      end

      def field_empty?(key)
        data[key].nil? || data[key].empty?
      end

      def prefix
        str = Base64.urlsafe_encode64("#{id}#{CMT.config.client.s3_delimiter}",
                                      padding: false)
        str[0..-2]
      end

      # @param type [:start, :end]
      def time(type)
        field = (type == :start) ? :ingest_start_time : :ingest_complete_time
        val = send(field)
        return nil if val.nil? || val.empty?

        CMT::Logs.timestamp_from_datestring(val).either(
          ->(success) { success },
          ->(failure) {}
        )
      end

      def printable_row
        [id, action, rec_ct, mappable_rectype,
          File.basename(source_csv)].join("\t")
      end

      def rewrite
        csv.rewrite
      end

      def show_info
        data.each do |key, value|
          next if value.nil? || value.empty?

          puts "#{key}: #{value}"
        end
      end

      def to_monad
        data ? Success(self) : Failure("No batch with id: #{id}")
      end

      def to_s
        datastr = data.reject { |_key, val| val.nil? || val.empty? }
          .map { |key, val| "  #{key}: #{val}" }
          .join("\n")
        <<~OBJ
          #<#{self.class.name}
          #{datastr}>
        OBJ
      end

      private

      attr_reader :csv, :id, :data, :dirpath

      def delete_batch_dir
        return Success() unless dirpath

        FileUtils.rm_rf(dirpath) if Dir.exist?(dirpath)
      rescue => err
        msg = "#{err.message} IN #{err.backtrace[0]}"
        Failure(CMT::Failure.new(context: "#{self.class.name}.#{__callee__}",
          message: msg))
      else
        Success()
      end

      def get_batch_data
        row = yield(csv.find_batch(id))
        @data = row

        Success()
      end
    end
  end
end
