# frozen_string_literal: true

module CollectionspaceMigrationTools
  module Csid
    # Uses client to delete records by CSID
    class Deleter
      include Dry::Monads[:result]
      include Dry::Monads::Do.for(:call)

      class << self
        def call(client:, row:)
          self.new(client: client).call(row: row)
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
        result = row['csid']
        return Success(result) if result

        msg = "No CSID in row"
        Failure(CMT::Failure.new(
          context: "#{self.class.name}.#{__callee__}", message: msg
        ))
      end

      def get_rectype(row)
        result = row['rectype']
        return Success(result) if result

        msg = "No rectype in row"
        Failure(CMT::Failure.new(
          context: "#{self.class.name}.#{__callee__}", message: msg
        ))
      end

      def get_client_response(path)
        result = client.delete(path)
      rescue StandardError => err
        msg = "#{err.message} IN #{err.backtrace[0]}"
        Failure(CMT::Failure.new(
          context: "#{self.class.name}.#{__callee__}", message: msg
        ))
      else
        return Success(result.parsed) if result.result.success?

        Failure(
          CMT::Failure.new(
            context: result.class.name,
            message: "#{result.status_code}: #{result.parsed}"
          )
        )
      end
    end
  end
end
