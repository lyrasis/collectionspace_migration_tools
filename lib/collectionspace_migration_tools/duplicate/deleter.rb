# frozen_string_literal: true

module CollectionspaceMigrationTools
  module Duplicate
    class Deleter
      include Dry::Monads[:result]
      include Dry::Monads::Do.for(:call, :duplicates, :deduplicate,
        :deduplicate_id)

      class << self
        def call(...)
          new(...).call
        end
      end

      # @param rectype [String] a mappable rectype
      def initialize(rectype:)
        @rectype = rectype
      end

      def call
        dupe_ids = yield duplicates
        if dupe_ids.num_tuples == 0
          puts "No duplicate #{rectype} records found"
          return Success()
        end

        client = yield CMT::Client.call
        basepath = yield CMT::RecordTypes.services_api_path(rectype)

        yield deduplicate(dupe_ids, client, basepath)

        Success()
      end

      def to_monad
        Success(self)
      end

      private

      attr_reader :rectype, :dupe_csv, :id, :action, :iteration, :remaining

      def duplicates
        obj = yield(CMT::RecordTypes.to_obj(rectype))
        dupes = yield(obj.duplicates)

        Success(dupes)
      end

      def ts(str)
        return Failure(:no_f) if str.start_with?("f")

        Success(str)
      end

      def tss(arr)
        res = arr.map { |str| ts(str) }
        return Success(:all_good) if res.all?(&:success?)

        Failure(res.select(&:failure?))
      end

      def deduplicate(tuples, client, basepath)
        results = tuples.values
          .flatten
          .map { |id| deduplicate_id(id, client, basepath) }
        _chk = yield check_compiled_results(results)

        Success()
      end

      def deduplicate_id(id, client, basepath)
        response = yield get_response(id, client, basepath)
        paths = response.parsed["abstract_common_list"]["list_item"]
          .map { |h| h["uri"] }
        paths.shift
        puts "Deleting #{paths.length} duplicate(s) of #{id}"

        results = paths.map { |path| delete_record(client, path, id) }
        _chk = yield check_compiled_results(results)

        Success()
      end

      def get_response(id, client, basepath)
        response = client.find(type: basepath, value: id)
        return Success(response) if response.result.success?

        Failure("Cannot lookup #{id}; API status code: #{response.status_code}")
      rescue => err
        Failure("Error looking up #{id}: #{err.message}")
      end

      def delete_record(client, path, id)
        response = client.delete(path)
        return Success() if response.result.success?

        Failure("Cannot delete #{path} (#{id}); "\
                "API status code: #{response.status_code}")
      rescue => err
        Failure("Error deleting #{path} (#{id}): #{err.message}")
      end

      def check_compiled_results(results)
        return Success() if results.all?(&:success?)

        Failure(results.select(&:failure?).map(&:failure))
      end
    end
  end
end
