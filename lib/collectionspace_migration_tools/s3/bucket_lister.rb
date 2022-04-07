# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module CollectionspaceMigrationTools
  module S3
    class BucketLister
      include Dry::Monads[:result]
      include Dry::Monads::Do.for(:call)

      
      class << self
        def call
          self.new.call
        end
      end

      def initialize
        @bucket = CMT.config.client.s3_bucket
      end

      def call
        client = yield(CMT::Build::S3Client.call)
        list = yield(get_list(client))

        Success(list)
      end
      
      private

      attr_reader :bucket

      def get_list(client)
        response = client.list_objects_v2({bucket: bucket})
      rescue StandardError => err
        msg = "#{err.message} IN #{err.backtrace[0]}"
        Failure(CMT::Failure.new(context: "#{self.class.name}.#{__callee__}", message: msg))
      else
        Success(response.contents.map(&:key))
      end
    end
  end
end
