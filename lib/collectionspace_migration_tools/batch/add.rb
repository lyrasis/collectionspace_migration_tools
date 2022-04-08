# frozen_string_literal: true

require 'csv'
require 'dry/monads'
require 'dry/monads/do'
require 'smarter_csv'

module CollectionspaceMigrationTools
  module Batch
    class Add
      include Dry::Monads[:result]
      include Dry::Monads::Do.for(:call, :validate_csv)
      
      class << self
        def call(...)
          self.new.call(...)
        end
      end
      
      def initialize
        @path = CMT.config.client.batch_csv
        @headers = CMT::Build::BatchesCsv.headers
        @ids = CMT::Batch::Csv.new.ids
      end

      def call(id:, csv:, rectype:, action:)
        valid_id = yield(validate_id(id))
        valid_csv = yield(validate_csv(csv))
        valid_rectype = yield(CMT::RecordTypes.valid_mappable?(rectype))
        valid_action = yield(validate_action(action))

        mapper = yield(CMT::Parse::RecordMapper.call(valid_rectype))
        rec_ct = yield(CMT::Batch::CsvRowCounter.call(valid_csv))

        data_hash = {
          'id' => valid_id,
          'source_csv' => valid_csv,
          'mappable_rectype' => valid_rectype,
          'action' => valid_action,
          'cacheable_type' => mapper.type_label,
          'cacheable_subtype' => mapper.subtype,
          'rec_ct' => rec_ct
        }
        _result = yield(write_row(data_hash))

        Success(data_hash)
      end
      
      private

      attr_reader :path, :headers, :ids

      def allowed_actions
        %w[create update delete]
      end

      def validate_action(action)
        return Success(action) if allowed_actions.any?(action)

        Failure("Invalid action: #{action}. Must be one of: #{allowed_actions.join(', ')}")
      end
      
      def validate_csv(csv)
        row_getter = yield(CMT::Csv::FirstRowGetter.new(csv))
        checker = yield(CMT::Csv::FileChecker.call(csv, row_getter))

        Success(checker[0])
      end

      def validate_id(id)
        return Success(id) unless ids.any?(id)

        Failure("There is already a batch with id: #{id}. Please choose another id")
      end

      def write_row(data_hash)
        CSV.open(path, 'a', headers: true){ |csv|
          csv << data_hash.fetch_values(*headers){ |_key| nil }
        }
      rescue StandardError => err
        msg = "#{err.message} IN #{err.backtrace[0]}"
        Failure(CMT::Failure.new(context: "#{self.class.name}.#{__callee__}", message: msg))
      else
        Success()
      end
    end
  end
end
