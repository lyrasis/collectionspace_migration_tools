# frozen_string_literal: true

module CollectionspaceMigrationTools
  module Config
    class System < CMT::Config::Section
      DEFAULT_PATH = CMT::Config.file_path(:system)

      # @param path [String]
      def initialize(path: DEFAULT_PATH, hash: nil)
        super
        # If you change default values here, update sample_system_config.yml
        @default_values = {
          db_port: 5432,
          db_connect_host: "localhost",
          db_tunnel_connection_pause: 3,
          db_tunnel_initial_connection_timeout: 30,
          db_tunnel_initial_connection_polling_interval: 2.5,
          csv_chunk_size: 50,
          max_threads: 10,
          max_processes: 6,
          aws_profile: "collectionspace",
          aws_media_ingest_profile: "shared",
          cs_app_version: "9_0",
          csv_col_sep: ",",
          csv_row_sep: "\n",
          csv_quote_char: '"',
          csv_quote_escaping: :double_quotes,
          csv_quote_boundary: :legacy,
          csv_strip_chars_from_headers: /"/,
          csv_convert_values_to_numeric: false,
          csv_strings_as_keys: true
        }
        @pathvals = %i[client_config_dir config_name_file
          cspace_config_untangler_dir term_manager_config_dir]
        @validator = CMT::Validate::ConfigSystemContract
      end

      private

      def manipulate
        %i[csv_quote_escaping csv_quote_boundary].each do |key|
          convert_to_symbol(key)
        end

        convert_to_regexp(:csv_strip_chars_from_headers)
      end

      def convert_to_symbol(key)
        return if hash[key].is_a?(Symbol)

        hash[key] = hash[key].to_sym
      end

      def convert_to_regexp(key)
        return if hash[key].is_a?(Regexp)

        hash[key] = Regexp.new(hash[key])
      end
    end
  end
end
