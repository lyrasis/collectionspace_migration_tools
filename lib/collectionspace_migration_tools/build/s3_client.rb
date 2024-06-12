# frozen_string_literal: true

require "aws-sdk-s3"
require "dry/monads"
require "dry/monads/do"

module CollectionspaceMigrationTools
  module Build
    # Returns AWS S3 client
    class S3Client
      include Dry::Monads[:result]
      include Dry::Monads::Do.for(:call)

      class << self
        def call
          new.call
        end
      end

      def initialize
        @profile = CMT.config.system.aws_profile
        @bucket = CMT.config.client.s3_bucket
      end

      def call
        return Failure(:no_S3_bucket_configured) unless bucket

        client = yield(create_client)
        _try = yield(try(client))

        Success(client)
      end

      private

      attr_reader :profile, :bucket

      def create_client
        client = Aws::S3::Client.new(
          profile: profile
        )
      rescue => err
        msg = "#{err.message} IN #{err.backtrace[0]}"
        Failure(CMT::Failure.new(context: "#{self.class.name}.#{__callee__}",
          message: msg))
      else
        Success(client)
      end

      def try(client)
        result = client.get_bucket_location({bucket: bucket})
      rescue => err
        msg = "#{err.message} IN #{err.backtrace[0]}"
        Failure(CMT::Failure.new(context: "#{self.class.name}.#{__callee__}",
          message: msg))
      else
        Success(result)
      end
    end
  end
end
