# frozen_string_literal: true

module CollectionspaceMigrationTools
  module Config
    class Client < CMT::Config::Section
      def initialize(hash:, context: nil)
        super

        # If you change default values here, update sample_client_config.yml
        @default_values = {
          page_size: 50,
          batch_dir: "batch_data",
          auto_refresh_cache_before_mapping: true,
          clear_cache_before_refresh: true,
          csv_delimiter: ",",
          s3_delimiter: "|",
          media_with_blob_upload_delay: 500,
          max_media_upload_threads: 5,
          archive_batches: true,
          batch_archive_filename: "batches_archive.csv",
          redis_db_number: 0
        }
        @validator = CMT::Validate::ConfigClientContract
        @pathvals = %i[base_dir batch_csv batch_config_path]
        @subdirvals = %i[batch_dir ingest_dir mapper_dir]
      end

      private

      def pre_manipulate
        add_option(:cs_app_version, nil)
        add_option(:mapper_dir, set_mapper_dir)
        add_option(:profile_version, set_profile_version)
        add_option(:ingest_dir, "ingest")
        return unless hosted?

        site = CHIA.site_for(hash.dig(:site_name))
        add_option(:base_uri, site.services_url)
        add_option(:username, site.user_name)
        add_option(:password, site.admin_password)

        db_creds = CMT::Database.db_credentials_for(site)
        %i[db_host db_username db_password db_name].each do |sym|
          add_option(sym, db_creds[sym])
        end
      end

      def hosted? = !hash.dig(:site_name).nil?

      def manipulate
        add_option(:batch_config_path, nil)
        add_option(:fast_import_bucket, nil)
        set_log_group_name
        add_option(:batch_csv, set_batch_csv)
        add_media_blob_delay
        add_option(:db_host, nil)
        add_option(:db_username, nil)
        add_option(:db_password, nil)
        add_option(:db_name, nil)
      end

      def set_mapper_dir
        return unless context

        version = hash[:cs_app_version] || context.cs_app_version
        return unless version

        [version, "release_#{version}"].map do |v|
          segments = [context.cspace_config_untangler_dir, "data", "mappers",
            "community_profiles", v, hash[:profile]].compact
          File.join(*segments)
        end.find { |path| Dir.exist?(path) }
      end

      def set_profile_version
        return unless hash[:mapper_dir] && Dir.exist?(hash[:mapper_dir])

        Dir.new(hash[:mapper_dir]).children.first.split("_")[1]
      end

      def set_log_group_name
        if hash.key?(:fast_import_bucket) && hash[:fast_import_bucket]
          add_option(
            :log_group_name,
            "/aws/lambda/#{hash[:fast_import_bucket]}"
          )
        end
      end

      def set_batch_csv
        return unless hash[:base_dir]

        File.join(hash[:base_dir], "batches.csv")
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
