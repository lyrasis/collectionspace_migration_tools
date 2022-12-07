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
        deriv.either(
          ->success{ success_to_h(success) },
          ->failure{ failure_to_h(failure) }
        )
      end

      def to_monad
        deriv
      end

      private

      attr_reader :blob, :deriv

      # @param data [CMT::Failure]
      def failure_to_h(data)
        blob.to_h
          .merge({
            'derivable?'=>'y',
            'check_success?'=>'n',
            'error_msgs'=>data.for_csv
          })
      end

      # @param data [CMT::Media::DerivData]
      def success_to_h(data)
        blob.to_h
          .merge(data.to_h)
          .merge({
            'derivable?'=>'y',
            'check_success?'=>'y'
          })
      end
    end
  end
end
