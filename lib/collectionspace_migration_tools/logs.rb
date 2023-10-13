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
  end
end
