# frozen_string_literal: true

require 'dry/validation'

module CollectionspaceMigrationTools
  module Validate
    class ConfigClientContract < CMT::Validate::ApplicationContract
      schema do
        required(:base_uri).filled(:string)
        required(:username).filled(:string)
        required(:password).filled(:string)
        required(:page_size).filled(:integer)
        required(:cs_version).filled(:string)
        required(:profile).filled(:string)
        required(:profile_version).filled(:string)
        required(:base_dir).filled(:string)
        optional(:batch_csv).maybe(:string)
        required(:mapper_dir).filled(:string)
        required(:batch_dir).filled(:string)
        required(:redis_db_number).filled(:integer)
        optional(:batch_config_path).maybe(:string)
        optional(:auto_refresh_cache_before_mapping).filled(:bool)
        optional(:clear_cache_before_refresh).filled(:bool)
        required(:csv_delimiter).filled(:string)
        required(:s3_bucket).filled(:string)
        required(:s3_delimiter).filled(:string)
        required(:max_media_upload_threads).filled(:integer)
        required(:media_with_blob_upload_delay).filled(:integer)
      end

      rule(:base_dir) do
        full = File.expand_path(value)
        unless Dir.exist?(full)
          key.failure("#{full} does not exist")
        end
      end

      rule(:base_uri) do
        key.failure(%(must end with "/cspace-services")) unless value.end_with?('/cspace-services')
      end

      rule(:batch_config_path) do
        if key?
          full = File.expand_path(value)
          unless File.exist?(full)
            key.failure("#{full} does not exist")
          end
        end
      end

      rule(:cs_version) do
        unless /^\d+_\d+$/.match(value)
          key.failure('must follow pattern: number underscore number')
        end
      end

      rule(:profile) do
        ok = %w[anthro bonsai botgarden core fcart herbarium lhmc materials ohc publicart]
        unless ok.any?(value)
          key.failure("must be one of: #{ok.join(', ')}")
        end
      end

      rule(:profile_version) do
        unless /^(\d+-){2,}\d+$/.match(value)
          key.failure('must follow pattern: number hyphen number hyphen number')
        end
      end

      rule(:username) do
        unless /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i.match?(value)
          key.failure('must be a valid email address')
        end
      end
    end
  end
end
