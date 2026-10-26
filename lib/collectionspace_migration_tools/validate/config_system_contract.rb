# frozen_string_literal: true

require "dry/validation"

module CollectionspaceMigrationTools
  module Validate
    class ConfigSystemContract < CMT::Validate::ApplicationContract
      params do
        required(:client_config_dir).filled(:string)
        required(:config_name_file).filled(:string)
        required(:cspace_config_untangler_dir).filled(:string)
        required(:cs_app_version).filled(:string)
        required(:csv_chunk_size).filled(:integer)
        required(:max_threads).filled(:integer)
        required(:aws_profile).filled(:string)
        required(:bastion_user).filled(:string)
        required(:db_port).filled(:integer)
        required(:db_connect_host).filled(:string)
        required(:db_tunnel_connection_pause).filled(:integer)
        required(:db_tunnel_initial_connection_timeout).filled(:integer)
        required(:db_tunnel_initial_connection_polling_interval).filled(:float)
        required(:csv_col_sep).filled(:string)
        required(:csv_row_sep).filled(:string)
        required(:csv_quote_char).filled(:string)
        required(:csv_quote_escaping).filled(:symbol)
        required(:csv_quote_boundary).filled(:symbol)
        required(:csv_strip_chars_from_headers)
        required(:csv_convert_values_to_numeric).filled(:bool)
        required(:csv_strings_as_keys).filled(:bool)
        optional(:aws_media_ingest_profile).maybe(:string)
        optional(:term_manager_config_dir).maybe(:string)
      end

      rule(:client_config_dir).validate(:dir_exists)
      rule(:cspace_config_untangler_dir).validate(:dir_exists)
      rule(:cs_app_version).validate(:valid_cs_version)
      rule(:config_name_file).validate(:file_exists_or_gets_created)
      rule(:term_manager_config_dir).validate(:dir_exists)

      rule(:csv_quote_escaping) do
        ok = %i[auto double_quotes backslash]

        unless ok.any?(value)
          key.failure("must be one of: #{ok.join(", ")}")
        end
      end

      rule(:csv_quote_boundary) do
        ok = %i[standard legacy]

        unless ok.any?(value)
          key.failure("must be one of: #{ok.join(", ")}")
        end
      end

      rule(:csv_strip_chars_from_headers) do
        key.failure("must be a Regexp") unless value.is_a?(Regexp)
      end
    end
  end
end
