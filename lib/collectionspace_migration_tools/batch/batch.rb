# frozen_string_literal: true

require "base64"
require "fileutils"

module CollectionspaceMigrationTools
  module Batch
    class Batch
      include Dry::Monads[:result]
      include Dry::Monads::Do.for(:call, :validate_csv, :delete,
        :get_batch_data)
      include CMT::Batch::Mappable
      include CMT::Batch::Uploadable
      include CMT::Batch::Ingestable

      attr_reader :mode

      def initialize(csv, id)
        @csv = csv
        @id = id
        get_batch_data
        @dirpath = "#{CMT.config.client.batch_dir}/#{dir}" if data && dir
        @config = set_config
        @mode = set_mode
      end

      def delete
        _status = yield(to_monad)
        _del_dir = yield(delete_batch_dir)
        _del_row = yield(csv.delete_batch(id))

        Success()
      end

      def is_done?
        return true if done? == "y"

        missing_vals = CMT::Batch::Csv::Headers.populated_if_done_headers
          .map { |field| send(field.to_sym) }
          .select { |val| val.nil? || val.empty? }
        missing_vals.empty? ? true : false
      end

      def get(field)
        val = send(field.to_sym)
        return Failure("No value for #{field}") if val.nil? || val.empty?

        Success(val)
      end

      def mark_done
        data["done?"] = "y"
        rewrite
      end

      # Each header from batches CSV becomes a method name returning the value for this batch
      def method_missing(meth, *args)
        str_meth = meth.to_s
        return data[str_meth] if data.key?(str_meth)

        message = "You called #{str_meth} with #{args}. This method doesn't exist."
        raise NoMethodError, message
      end

      def populate_field(key, value)
        return Failure("#{key} is not a valid field") unless data.key?(key)
        return Failure("#{key} is already populated") unless data[key].nil? || data[key].empty?

        data[key] = value
        Success(data)
      end

      def prefix
        str = Base64.urlsafe_encode64("#{id}#{CMT.config.client.s3_delimiter}",
          padding: false)
        str[0..-2]
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

      attr_reader :csv, :id, :data, :dirpath, :config

      def set_config
        CMT::Parse::BatchConfig.call
          .either(
            ->(success) { success },
            ->(failure) { {} }
          )
      end

      def set_mode
        return config["batch_mode"] if config.key?("batch_mode")

        "full record"
      end

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
