# frozen_string_literal: true

require 'csv'
require 'dry/monads'

module CollectionspaceMigrationTools
  module Csv
    # Handles writing batch report CSV
    class BatchReporter
      include Dry::Monads[:result]

      def initialize(output_dir:, fields:, term_reporter:)
        @path = "#{output_dir}/mapper_report.csv"
        @fields = [fields, 'CMT_rec_status', 'CMT_outcome', 'CMT_warnings', 'CMT_errors'].flatten
        @term_reporter = term_reporter
        CSV.open(path, 'wb'){ |csv| csv << @fields }
      end

      def report_failure(result, source)
        response = get_response(result, source)
        data = response.orig_data
        data['CMT_rec_status'] = response.record_status
        data['CMT_outcome'] = 'failure'
        data['CMT_warnings'] = compile_warnings(response)
        write_row(add_errors(result, data, source))
      end

      def report_success(result)
        data = result.orig_data
        data['CMT_rec_status'] = result.record_status
        data['CMT_outcome'] = 'success'
        data['CMT_warnings'] = compile_warnings(result)
        write_row(data)
      end

      def to_monad
        Success(self)
      end
      
      private
      
      attr_reader :path, :fields, :term_reporter

      def add_errors(result, data, source)
        if source.class.name.end_with?('RowProcessor')
          add_row_processor_errors(result, data)
        else
          add_xml_writer_errors(result, data)
        end
      end

      def add_row_processor_errors(result, data)
        data['CMT_errors'] = compile_processor_errors(result)
        term_reporter.call(result) if term_errors?(result)

        data
      end

      def add_xml_writer_errors(result, data)
        error = result[0]
        response = result[1]
        if error == :file_already_exists
          data['CMT_errors'] = "An XML record with identifier #{response.identifier} has already been written. Check for duplicates"
        elsif error == :error_on_write
          data['CMT_errors'] = "Attempt to write XML to file raised error: #{result[2]}"
        elsif error == :cannot_delete_new_record
          data['CMT_errors'] = "Cannot delete new record"
        else
          data['CMT_errors'] = 'Unable to write file for unknown reason.'
        end

        data
      end

      def compile_processor_errors(result)
        result.errors.map{ |err| "#{err[:category]}: #{err[:message]}" }.join("; ")
      end
      
      def compile_warnings(result)
        warnings = result.warnings
        return nil if warnings.empty?
        
        result.warnings.map{ |warning| warning[:message] }.join("; ")
      end

      def get_response(result, source)
        if source.class.name.end_with?('RowProcessor')
          result
        else
          result[1]
        end
      end

      def term_errors?(result)
        result.errors.any?{ |err| err[:category] == :no_records_found_for_term }
      end

      def write_row(data)
        row = data.fetch_values(*fields){ |_key| nil }
        CSV.open(path, 'a'){ |csv| csv << row }
      end
    end
  end
end
