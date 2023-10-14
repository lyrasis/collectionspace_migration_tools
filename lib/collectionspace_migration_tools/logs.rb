# frozen_string_literal: true

module CollectionspaceMigrationTools
  module Logs
    extend Dry::Monads[:result, :do]

    def client_response(client, command, params)
      response = client.send(command, params)
    rescue => err
      msg = "#{err.message} IN #{err.backtrace[0]}"
      Failure(
        CMT::Failure.new(
          context: "#{name}.#{__callee__}", message: msg
        )
      )
    else
      Success(response)
    end
    def setup_client(client)
      if client.is_a?(Aws::CloudWatchLogs::Client)
        client
      elsif client.is_a?(Dry::Monads::Success)
        client.value!
      elsif client.is_a?(Dry::Monads::Failure)
        client.failure
      else
        raise "Unknown client class"
      end
    end
  end
end
