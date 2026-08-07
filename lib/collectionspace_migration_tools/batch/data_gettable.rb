# frozen_string_literal: true

module CollectionspaceMigrationTools
  module Batch
    module DataGettable
      include Dry::Monads::Do.for(:fast_importer_log_events)

      def get_batch_data(batch, field)
        val = batch.send(field.to_sym)
        if val.nil? || val.empty?
          Failure("No #{field} found for batch #{id}")
        else
          Success(val)
        end
      end

      def fast_importer_log_events(batch)
        st = yield get_batch_data(batch, "ingest_start_time")
        starttime = yield CMT::Logs.timestamp_from_datestring(st)
        events = yield CMT::Logs::BatchEventsFiltered.call(
          batchid: batch.id,
          pattern: "%Decoded batch\\x3A #{batch.id}\\s%",
          start_time: starttime
        )

        Success(events)
      end
    end
  end
end
