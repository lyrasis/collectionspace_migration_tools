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
        @data = csv.find_batch(id)
      end

      def to_monad
        data.success? ? Success(self) : Failure(data)
      end

      def method_missing(meth, *args)
        str_meth = meth.to_s
        dataval = data.value!
        return dataval[str_meth] if dataval.key?(str_meth)

        message = "You called #{str_meth} with #{args}. This method doesn't exist."
        raise NoMethodError, message
      end
      
      private

      attr_reader :csv, :id, :data

    end
  end
end
