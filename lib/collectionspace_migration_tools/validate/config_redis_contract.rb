# frozen_string_literal: true

require 'dry/validation'
require 'redis'

module CollectionspaceMigrationTools
  module Validate
    class ConfigRedisContract < CMT::Validate::ApplicationContract
      params do
        required(:refname_port).filled(:integer)
        required(:csid_port).filled(:integer)
      end

      rule(:refname_port, :csid_port) do
        checked = check_connection(value)
        key.failure("Redis not available on port #{value}") unless checked == 'PONG'
      end

      private

      def check_connection(port)
        redis = Redis.new(port: port)
        status = redis.ping
      rescue
        'nope'
      else
        status
      end
    end
  end
end
