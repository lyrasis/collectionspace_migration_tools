# frozen_string_literal: true

require "dry/validation"

module CollectionspaceMigrationTools
  module Validate
    class ConfigSystemContract < CMT::Validate::ApplicationContract
      params do
        required(:client_config_dir).filled(:string)
        required(:config_name_file).filled(:string)
        required(:csv_chunk_size).filled(:integer)
        required(:max_threads).filled(:integer)
        required(:aws_profile).filled(:string)
        required(:bastion_user).filled(:string)
        required(:db_port).filled(:integer)
        required(:db_connect_host).filled(:string)
        optional(:aws_media_ingest_profile).maybe(:string)
        optional(:term_manager_config_dir).maybe(:string)
      end

      rule(:client_config_dir).validate(:dir_exists)
      rule(:config_name_file).validate(:file_exists)
      rule(:term_manager_config_dir).validate(:dir_exists)
    end
  end
end
