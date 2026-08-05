# frozen_string_literal: true

module CollectionspaceMigrationTools
  module Csid
    # Uses client to delete records by CSID
    class Deleter
      include Dry::Monads[:result]
      include Dry::Monads::Do.for(:call)

      class << self
        def call(client:, row:)
          new(client: client).call(row: row)
        end
      end

      def initialize(client:)
        @client = client
      end

      def call(row:)
        rectype = yield get_rectype(row)
        basepath = yield CMT::RecordTypes.services_api_path(rectype)
        csid = yield get_csid(row)

        path = "/#{basepath}/#{csid}"
        _response = yield get_client_response(path)

        Success()
      end

      def to_monad
        Success(self)
      end

      private

      attr_reader :client

      def get_csid(row)
        result = row["csid"]
        return Success(result) if result

        Failure("No CSID in row")
      end

      def get_rectype(row)
        result = row["rectype"]
        return Success(result) if result

        Failure("No rectype in row")
      end

      def get_client_response(path)
        result = client.delete(path)
        return Success(result.parsed) if result.result.success?

        Failure("#{result.status_code}: #{result.parsed}")
      rescue => err
        Failure(err.message)
      end
    end
  end
end
