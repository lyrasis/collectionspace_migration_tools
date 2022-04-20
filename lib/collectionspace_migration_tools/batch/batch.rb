# frozen_string_literal: true

require 'base64'
require 'fileutils'

module CollectionspaceMigrationTools
  module Batch
    class Batch
      include Dry::Monads[:result]
      include Dry::Monads::Do.for(:call, :validate_csv, :delete, :get_batch_data)
      include CMT::Batch::Mappable
      include CMT::Batch::Uploadable
      include CMT::Batch::Ingestable
      
      def initialize(csv, id)
        @csv = csv
        @id = id
        get_batch_data
        @dirpath = "#{CMT.config.client.batch_dir}/#{dir}" if dir
      end

      def delete
        _del_dir = yield(delete_batch_dir)
        _del_row = yield(csv.delete_batch(id))

        Success()
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
        str = Base64.urlsafe_encode64("#{id}#{CMT.config.client.s3_delimiter}", padding: false)
        str[0..-2]
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

      private

      attr_reader :csv, :id, :data, :dirpath

      def delete_batch_dir
        return Failure("Batch directory for #{id} does not exist") unless dirpath
        
        FileUtils.rm_rf(dirpath) if Dir.exists?(dirpath)
      rescue StandardError => err
        msg = "#{err.message} IN #{err.backtrace[0]}"
        Failure(CMT::Failure.new(context: "#{self.class.name}.#{__callee__}", message: msg))
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
