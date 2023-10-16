# frozen_string_literal: true

require "dry/monads"
require "dry/monads/do"

module CollectionspaceMigrationTools
  module Batch
    # Ensures batch id is 6 or fewer characters and only alphanumeric
    class Id
      include Dry::Monads[:result]
      include Dry::Monads::Do.for(:to_monad)

      def initialize(str)
        @str = str
      end

      def to_monad
        _length = yield(check_length)
        _chars = yield(check_chars)

        Success(str)
      end

      def validate
        to_monad
      end

      private

      attr_reader :str

      def check_chars
        return Success() if str.match?(/^[A-Za-z0-9]+$/)

        Failure("Batch ID must consist of only letters and numbers")
      end

      def check_length
        return Success() if str.length <= 6

        Failure("Batch ID must be 6 or fewer characters")
      end
    end
  end
end
