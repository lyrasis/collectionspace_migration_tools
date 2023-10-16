# frozen_string_literal: true

module CollectionspaceMigrationTools
  module Batch
    module DataGettable
      extend Dry::Monads[:result]

      def get_batch_data(batch, field)
        val = batch.send(field.to_sym)
        if val.nil? || val.empty?
          Failure("No #{field} found for batch #{id}")
        else
          Success(val)
        end
      end
    end
  end
end
