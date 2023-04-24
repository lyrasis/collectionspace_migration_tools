# frozen_string_literal: true

module CollectionspaceMigrationTools
  module S3
    class BucketPolicySetter
      include Dry::Monads[:result]
      include Dry::Monads::Do.for(:call)

      class << self
        def call(...)
          self.new(...).call
        end
      end

      # @param policy [:private, :public]
      def initialize(policy:)
        @policy = policy
        @public_access_block = policy == :private ? true : false
      end

      def call
        @bucket = yield get_bucket
        @client = yield CMT::Build::S3MediaClient.call
        _block_set = yield set_public_access_block
        _policy_set = yield set_policy

        Success()
      end

      def to_monad
        Success(self)
      end

      private

      attr_reader :bucket, :client, :policy, :public_access_block

      def get_bucket
        return Failure(CMT::Failure.new(
          context: "#{self.class.name}.#{__callee__}",
          message: "No client media_bucket setting specified"
        )) unless CMT.config.client.respond_to?(:media_bucket)

        Success(CMT.config.client.media_bucket)
      end

      def set_public_access_block
        resp = client.put_public_access_block({
          bucket: bucket,
          public_access_block_configuration: public_access_block_config
        })
      rescue => err
        msg = "#{err.message} IN #{err.backtrace[0]}"
        Failure(
          CMT::Failure.new(
            context: "#{self.class.name}.#{__callee__}",
            message: msg
          )
        )
      else
        Success(resp)
      end

      def public_access_block_config
        {
          block_public_acls: public_access_block,
          ignore_public_acls: public_access_block,
          block_public_policy: public_access_block,
          restrict_public_buckets: public_access_block,
        }
      end

      def set_policy
        if policy == :public
          resp = client.put_bucket_policy({
            bucket: bucket,
            policy: public_policy
          })
        else
          resp = client.delete_bucket_policy({
            bucket: bucket
          })
        end
      rescue => err
        msg = "#{err.message} IN #{err.backtrace[0]}"
        Failure(
          CMT::Failure.new(
            context: "#{self.class.name}.#{__callee__}",
            message: msg
          )
        )
      else
        Success(resp)
      end

      def public_policy
        "{\"Version\": \"2008-10-17\", \"Statement\": [ { \"Sid\": \"AllowPublicRead\", \"Effect\": \"Allow\", \"Principal\": { \"AWS\": \"*\" }, \"Action\": \"s3:GetObject\", \"Resource\": \"arn:aws:s3:::#{bucket}/*\" }, { \"Sid\": \"Stmt1546414471931\", \"Effect\": \"Allow\", \"Principal\": { \"AWS\": \"*\" }, \"Action\": \"s3:ListBucket\", \"Resource\": \"arn:aws:s3:::#{bucket}\" } ]}"
      end
    end
  end
end
