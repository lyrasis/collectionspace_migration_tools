# frozen_string_literal: true

require 'aws-sdk-s3'
require 'dry/monads'
require 'dry/monads/do'

module CollectionspaceMigrationTools
  module S3
  # Returns AWS S3 client
    class Uploader
      include Dry::Monads[:result]
      include Dry::Monads::Do.for(:call)
      
      def initialize(file_dir:, client:)
        @file_dir = "#{CMT.config.client.xml_dir}/#{file_dir}"
        @client = client
        @bucket = CMT.config.client.s3_bucket
        @to_upload = Queue.new
      end

      def call
      end
      
      private

      attr_reader :file_dir, :client, :bucket


    end
  end
end
