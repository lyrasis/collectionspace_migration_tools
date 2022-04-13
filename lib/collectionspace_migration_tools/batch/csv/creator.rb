# frozen_string_literal: true

require 'csv'

module CollectionspaceMigrationTools
  module Batch
    module Csv
      # Creates new batches CSV
      class Creator
        include Dry::Monads[:result]

        class << self
          def call
            self.new.call
          end

          def headers
            %w[
               id source_csv mappable_rectype action
               refname_dependencies csid_dependencies
               rec_ct
               mapped? dir map_errs map_oks map_warns
               uploaded? upload_errs upload_oks
               batch_prefix
               ingest_checked? ingest_errs ingest_oks
               duplicates_checked? duplicates
               done?
              ]
          end
        end

        def initialize
          @path = CMT.config.client.batch_csv
          @headers = self.class.headers
        end

        def call
          if File.exists?(path)
            puts "#{path} already exists; leaving it alone"
            unless headers_match?
              warn('WARNING: Batch CSV headers are not up-to-date. Run `thor batches:update_csv` to fix')
            end
            
            Success()
          else
            build_batches_csv
          end
        end
        
        private

        attr_reader :path, :headers

        def build_batches_csv
          CSV.open(path, 'wb'){ |csv| csv << headers }
        rescue StandardError => err
          msg = "#{err.message} IN #{err.backtrace[0]}"
          Failure(CMT::Failure.new(context: "#{self.class.name}.#{__callee__}", message: msg))
        else
          File.exists?(path) ? Success() : Failure()
        end

        def headers_match?
          row = File.open(path){ |file| CSV.parse_line(file, headers: true) }
          row.headers == self.headers
        end
      end
    end
  end
end
