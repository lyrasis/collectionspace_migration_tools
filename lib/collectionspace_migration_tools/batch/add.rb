# frozen_string_literal: true

require 'csv'
require 'smarter_csv'

module CollectionspaceMigrationTools
  module Batch
    class Add
      include Dry::Monads[:result]
      include Dry::Monads::Do.for(:call, :validate_csv, :validate_id)
      
      class << self
        def call(...)
          self.new.call(...)
        end
      end
      
      def initialize
        @path = CMT.config.client.batch_csv
        @headers = CMT::Batch::Csv::Headers.call
        @ids = CMT::Batch::Csv::Reader.new.ids
      end

      def call(id:, csv:, rectype:, action:)
        valid_id = yield(validate_id(id))
        valid_csv = yield(validate_csv(csv))
        valid_rectype = yield(CMT::RecordTypes.valid_mappable?(rectype))
        valid_action = yield(validate_action(action))

        mapper = yield(CMT::Parse::RecordMapper.call(valid_rectype))
        entity_type = mapper.service_type
        
        rec_ct = yield(CMT::Batch::CsvRowCounter.call(valid_csv[0]))

        refname_deps = yield(CMT::Batch::RefnameCacheDependencyIdentifier.call(headers: valid_csv[1].headers, mapper: mapper))
        csid_deps = yield(CMT::Batch::CsidCacheDependencyIdentifier.call(path: valid_csv[0], mapper: mapper))
        
        data_hash = {
          'id' => valid_id,
          'source_csv' => valid_csv[0],
          'mappable_rectype' => valid_rectype,
          'action' => valid_action,
          'entity_type' => entity_type,
          'refname_dependencies' => refname_deps,
          'csid_dependencies' => csid_deps,
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

      def ensure_id_uniqueness(id)
        return Success(id) unless ids.any?(id)

        Failure("There is already a batch with id: #{id}. Please choose another id")
      end

      def validate_action(action)
        return Success(action) if allowed_actions.any?(action)

        Failure("Invalid action: #{action}. Must be one of: #{allowed_actions.join(', ')}")
      end
      
      def validate_csv(csv)
        row_getter = yield(CMT::Csv::FirstRowGetter.new(csv))
        checker = yield(CMT::Csv::FileChecker.call(csv, row_getter))

        Success(checker)
      end

      def validate_id(id)
        _valid = yield(CMT::Batch::Id.new(id).validate)
        _uniq = yield(ensure_id_uniqueness(id))

        Success(id)
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
