# frozen_string_literal: true

module CollectionspaceMigrationTools
  module VocabularyTerms
    # Handles writing output of all vocabulary terms query
    class Reporter
      include Dry::Monads[:result]
      include Dry::Monads::Do.for(:call, :term_data)

      # @param path [String] to write output
      # @param include_deletes [Boolean] whether to include soft deletes
      def initialize(path:, include_deletes: false)
        @path = path
        @include_deletes = include_deletes
      end

      def call
        rows = yield term_data
        _written = yield write(rows)

        puts "Wrote vocabulary terms to #{path}"
        Success()
      end

      def to_monad
        Success(self)
      end

      private

      attr_reader :path, :include_deletes

      # @return [Array<Hash>]
      def term_data
        query = yield CMT::Entity::Vocabulary.new.full_data_query
        puts "\nQuerying for vocabulary terms..."
        rows = yield CMT::Database::ExecuteQuery.call(query)
        return Success(rows.to_a) if include_deletes

        result = rows.to_a
          .map { |row| reject_deleted(row) }
          .compact

        Success(result)
      end

      def reject_deleted(row)
        return if row["lifecyclestate"] == "deleted"

        row.delete("lifecyclestate")
        row
      end

      def write(rows)
        CSV.open(path, "w") do |csv|
          csv << headers(rows)
          rows.each { |row| csv << row.values }
        end

        Success()
      rescue => err
        msg = "#{err.message} IN #{err.backtrace[0]}"
        Failure(CMT::Failure.new(
          context: "#{name}.#{__callee__}(#{key})", message: msg
        ))
      end

      def headers(rows) = rows.first.keys
    end
  end
end
