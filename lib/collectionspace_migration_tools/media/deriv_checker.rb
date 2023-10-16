# frozen_string_literal: true

module CollectionspaceMigrationTools
  module Media
    # Uses client to make and extract data from
    #   `/blobs/{csid}/derivatives` API calls
    class DerivChecker
      include Dry::Monads[:result]
      include Dry::Monads::Do.for(:call)

      class << self
        def call(client:, blobcsid:, obj: CMT::Media::DerivData)
          new(client: client, obj: obj).call(blobcsid: blobcsid)
        end
      end

      def initialize(client:, obj: CMT::Media::DerivData)
        @client = client
        @obj = obj
      end

      def call(blobcsid:)
        path = "/blobs/#{blobcsid}/derivatives"
        response = yield get_client_response(path)

        Success(obj.new(blobcsid: blobcsid, response: response))
      end

      def to_monad
        Success(self)
      end

      private

      attr_reader :client, :obj

      def get_client_response(path)
        result = client.get(path)
      rescue => err
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
