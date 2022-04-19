# frozen_string_literal: true

require 'csv'
require 'dry/monads'

module CollectionspaceMigrationTools
  module S3
    # Handles writing upload report CSV
    class UploadReporter
      include Dry::Monads[:result]

      attr_reader :path
      
      def initialize(output_dir:, fields:)
        @path = "#{output_dir}/upload_report.csv"
        @fields = [fields, 'cmt_upload_status', 'cmt_upload_message'].flatten
        CSV.open(path, 'wb'){ |csv| csv << @fields }
      end

      def report_failure(failure, row)
        row['cmt_upload_status'] = 'failure'
        row['cmt_upload_message'] = process_failure(failure)
        write_row(row)
      end

      def report_mapping_failure(row)
        row['cmt_upload_status'] = 'skip'
        write_row(row)
      end
      
      def report_success(row)
        row['cmt_upload_status'] = 'success'
        write_row(row)
      end

      def report_unuploadable(row)
        row['cmt_upload_status'] = 'unuploadable'
        row['cmt_upload_message'] = 'row is missing cmt_output_file and/or cmt_s3_key values'
        write_row(row)
      end

      def to_monad
        Success(self)
      end
      
      private
      
      attr_reader :fields

      def process_failure(failure)
        if failure.is_a?(CMT::Failure)
          failure.message
        else
          failure
        end
      end

      def write_row(data)
        row = data.fetch_values(*fields){ |_key| nil }
        CSV.open(path, 'a'){ |csv| csv << row }
      end
    end
  end
end
