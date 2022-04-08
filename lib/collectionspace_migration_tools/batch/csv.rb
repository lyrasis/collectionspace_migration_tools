# frozen_string_literal: true

require 'csv'

module CollectionspaceMigrationTools
  module Batch
    class Csv
      def initialize
        @table = CSV.parse(File.read(CMT.config.client.batch_csv), headers: true)
      end

      def ids
        table.by_col!['id']
      end
      
      private

      attr_reader :table
    end
  end
end
