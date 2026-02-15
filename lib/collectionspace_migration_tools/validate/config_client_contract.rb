# frozen_string_literal: true

require "dry/validation"

module CollectionspaceMigrationTools
  module Validate
    class ConfigClientContract < CMT::Validate::ApplicationContract
      schema do
        optional(:archive_batches).filled(:bool)
        optional(:batch_archive_filename).maybe(:string)
        required(:base_uri).filled(:string)
        required(:username).filled(:string)
        required(:password).filled(:string)
        required(:page_size).filled(:integer)
        required(:profile).filled(:string)
        optional(:cs_app_version).maybe(:string)
        optional(:profile_version).maybe(:string)
        required(:base_dir).filled(:string)
        optional(:ingest_dir).filled(:string)
        optional(:batch_csv).maybe(:string)
        required(:mapper_dir).filled(:string)
        required(:batch_dir).filled(:string)
        optional(:redis_db_number).maybe(:integer)
        optional(:batch_config_path).maybe(:string)
        optional(:auto_refresh_cache_before_mapping).filled(:bool)
        optional(:clear_cache_before_refresh).filled(:bool)
        required(:csv_delimiter).filled(:string)
        optional(:fast_import_bucket).filled(:string)
        required(:s3_delimiter).filled(:string)
        required(:max_media_upload_threads).filled(:integer)
        required(:media_with_blob_upload_delay).filled(:float)
        optional(:media_bucket).maybe(:string)
        optional(:db_host).filled(:string)
        optional(:db_username).filled(:string)
        optional(:db_password).filled(:string)
        optional(:db_name).filled(:string)
      end

      register_macro(:subdir_exists) do
        unless value.nil?
          path = if ["~", "/"].any? { |char| value.start_with?(char) }
            File.expand_path(value)
          else
            File.join(File.expand_path(values[:base_dir]), value)
          end
          unless Dir.exist?(path)
            key.failure("#{path} does not exist")
          end
        end
      end

      rule(:base_dir).validate(:dir_exists)

      rule(:ingest_dir).validate(:subdir_exists)

      rule(:mapper_dir).validate(:subdir_exists)
      rule(:cs_app_version).validate(:valid_cs_version)

      rule(:base_uri) do
        unless value.end_with?("/cspace-services")
          key.failure(%(must end with "/cspace-services"))
        end
      end

      rule(:batch_config_path) do
        if key? && value
          full = File.expand_path(value)
          unless File.exist?(full)
            key.failure("#{full} does not exist")
          end
        end
      end

      rule(:profile) do
        ok = %w[anthro bonsai botgarden core fcart herbarium lhmc materials ohc
          omca publicart]
        unless ok.any?(value)
          key.failure("must be one of: #{ok.join(", ")}")
        end
      end

      rule(:profile_version) do
        next unless value

        unless /^(\d+-){2,}\d+(?:-rc\d+|)$/.match?(value)
          key.failure("must follow pattern: number hyphen number hyphen number")
        end
      end

      rule(:username) do
        unless /\A[\w+\-.]+@[a-z\d-]+(\.[a-z\d-]+)*\.[a-z]+\z/i.match?(value)
          key.failure("must be a valid email address")
        end
      end
    end
  end
end
