# frozen_string_literal: true

module CollectionspaceMigrationTools
  module Build
    # Returns AWS S3 client for interacting with media ingest bucket
    class S3MediaClient < S3Client
      def initialize
        @profile = CMT.config.system.aws_media_ingest_profile
        @bucket = CMT.config.client.media_bucket
      end
    end
  end
end
