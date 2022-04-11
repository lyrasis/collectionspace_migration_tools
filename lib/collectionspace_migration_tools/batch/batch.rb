# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module CollectionspaceMigrationTools
  module Batch
    class Batch
      include Dry::Monads[:result]
      include Dry::Monads::Do.for(:call, :validate_csv)
      
      def initialize(csv, id)
        @csv = csv
        @id = id
        get_batch_data
      end

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

      def rewrite
        csv.rewrite
      end
      
      def to_monad
        data ? Success(self) : Failure("No batch with id: #{id}")
      end

      private

      attr_reader :csv, :id, :data

      def get_batch_data
        csv.find_batch(id).fmap{ |row| @data = row }
      end

    end
  end
end
