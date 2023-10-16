# frozen_string_literal: true

require "csv"

module CollectionspaceMigrationTools
  module Batch
    module Csv
      # Creates new batches CSV
      class Creator
        include CMT::Batch::Csv::Headers
        include Dry::Monads[:result]

        class << self
          def call
            new.call
          end
        end

        def initialize
          @path = CMT.config.client.batch_csv
          @headers = all_headers
        end

        def call
          if File.exist?(path)
            puts "#{path} already exists; leaving it alone"

            Success()
          else
            build_batches_csv
          end
        end

        private

        attr_reader :path, :headers

        def build_batches_csv
          CSV.open(path, "wb") { |csv| csv << headers }
        rescue => err
          msg = "#{err.message} IN #{err.backtrace[0]}"
          Failure(CMT::Failure.new(context: "#{self.class.name}.#{__callee__}",
            message: msg))
        else
          File.exist?(path) ? Success() : Failure()
        end
      end
    end
  end
end
