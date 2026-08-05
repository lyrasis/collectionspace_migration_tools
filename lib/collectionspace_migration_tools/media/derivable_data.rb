# frozen_string_literal: true

module CollectionspaceMigrationTools
  module Media
    class DerivableData
      # @param blob [CSV::Row]
      # @param deriv [Dry::Monad::Result(CMT::Media::DerivData)]
      def initialize(blob:, deriv:)
        @blob = blob
        @deriv = deriv
      end

      def to_h
        return success_to_h(deriv.value!) if deriv.success?

        failure_to_h(deriv)
      end

      def to_monad
        deriv
      end

      private

      attr_reader :blob, :deriv

      # @param deriv [Dry::Monads::Failure]
      def failure_to_h(deriv)
        blob.to_h
          .merge({
            "derivable?" => "y",
            "check_success?" => "n",
            "error_msgs" => CMT::Failure.for_csv(deriv)
          })
      end

      # @param data [CMT::Media::DerivData]
      def success_to_h(data)
        blob.to_h
          .merge(data.to_h)
          .merge({
            "derivable?" => "y",
            "check_success?" => "y"
          })
      end
    end
  end
end
