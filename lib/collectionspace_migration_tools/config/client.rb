# frozen_string_literal: true

module CollectionspaceMigrationTools
  module Config
    class Client < CMT::Config::Section
      def initialize(hash:)
        super
        # If you change default values here, update sample_client_config.yml
        @default_values = {
          page_size: 50,
          cs_version: "7_2",
          batch_dir: "batch_data",
          auto_refresh_cache_before_mapping: true,
          clear_cache_before_refresh: true,
          csv_delimiter: ",",
          s3_delimiter: "|",
          media_with_blob_upload_delay: 500,
          max_media_upload_threads: 5,
          archive_batches: true,
          batch_archive_filename: "batches_archive.csv"
        }
        @validator = CMT::Validate::ConfigClientContract
        @pathvals = %i[base_dir batch_csv batch_config_path]
        @subdirvals = %i[batch_dir ingest_dir mapper_dir]
      end

      private

      def pre_manipulate
        return unless hosted?

        tenant = CHIA.tenant_for(hash.dig(:tenant_name))
        add_option(:base_uri, tenant.services_url)
        add_option(:username, tenant.user_name)
        add_option(:password, tenant.admin_password)
        hash[:base_uri] = hash[:base_uri].delete_suffix("/")
      end

      def hosted? = !hash.dig(:tenant_name).nil?

      def manipulate
        add_option(:batch_config_path, nil)
        add_option(:s3_bucket, nil)
        set_log_group_name
        add_option(:batch_csv, File.join(hash[:base_dir], "batches.csv"))
        add_media_blob_delay
      end

      def set_log_group_name
        if hash.key?(:s3_bucket) && hash[:s3_bucket]
          add_option(
            :log_group_name,
            "/aws/lambda/#{hash[:s3_bucket]}"
          )
        end
      end

      def add_media_blob_delay
        key = :media_with_blob_upload_delay
        if hash.key?(key)
          hash[key] = case hash[key]
          when 0
            0.0
          else
            Rational("#{hash[key]}/1000").to_f
          end
        else
          add_option_to_section(:media_with_blob_upload_delay, 0)
        end
      end
    end
  end
end
