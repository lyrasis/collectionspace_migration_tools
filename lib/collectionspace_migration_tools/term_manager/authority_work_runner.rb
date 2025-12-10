# frozen_string_literal: true

module CollectionspaceMigrationTools
  module TermManager
    class AuthorityWorkRunner < VocabWorkRunner
      include Dry::Monads[:result]
      include Dry::Monads::Do.for(:call, :runner_for, :hierarchy_runner,
        :get_known_fields)

      def call
        switch = yield CMT::Config::Switcher.call(client: instance.id)
        CMT.instance_variable_set(:@config, switch)
        @ingest_dir = CMT.config.client.ingest_dir
        %w[create update delete].each do |action|
          to_log(runner_for(action), action)
        end
        to_log(hierarchy_runner, "hierarchy")
        finish
      end

      private

      attr_reader :ingest_dir

      def runner_for(action)
        meth = :"#{action}s"
        terms = plan.send(meth)
        return Success("Nothing to do") if terms.empty?

        all_fields = yield get_known_fields

        used_fields = terms.map { |term| term.keys }
          .flatten
          .uniq
        headers = all_fields.intersection(used_fields)

        ingest_csv_name = "shared_#{vocab.type}-"\
          "#{vocab.mappable_rectype_name}-"\
          "#{vocab.source_code}-#{action}.csv"
        ingest_path = yield write_csv(ingest_csv_name, headers, terms)
        batchid = "#{terms.first["batchid"]}#{action[0]}"
        _added = CMT::Batch::Add.call(
          id: batchid,
          rectype: vocab.mappable_rectype_name,
          action: action,
          csv: ingest_path
        )

        Success("Batch generated")
      end

      def hierarchy_runner
        terms = plan.creates
          .select { |t| t.key?("broader_term") }
        return Success("No hierarchy") if terms.empty?

        rows = terms.map do |term|
          {
            "narrower_term" => term["termDisplayName"],
            "broader_term" => term["broader_term"],
            "term_type" => term["hierarchyType"],
            "term_subtype" => term["hierarchySubtype"]
          }
        end

        headers = rows.first.keys

        ingest_csv_name = "shared_#{vocab.type}-"\
          "#{vocab.mappable_rectype_name}-"\
          "#{vocab.source_code}-hier.csv"
        ingest_path = yield write_csv(ingest_csv_name, headers, rows)
        batchid = "#{terms.first["batchid"]}h"
        _added = CMT::Batch::Add.call(
          id: batchid,
          rectype: "authorityhierarchy",
          action: "create",
          csv: ingest_path
        )

        Success("Batch generated")
      end

      def get_known_fields
        if instance_variable_defined?(:@known_fields)
          return Success(@known_fields)
        end

        ent = yield CMT::RecordTypes.to_obj(vocab.mappable_rectype_name)
        all_fields = ent.mappings.map { |m| m["datacolumn"] }
        @known_fields = all_fields
        Success(all_fields)
      rescue => err
        Failure(CMT::Failure.new(context: "#{name}.#{__callee__}",
          message: err.message))
      end

      def write_csv(filename, headers, rows)
        path = File.join(ingest_dir, filename)
        CSV.open(path, "wb") do |csv|
          csv << headers
          rows.each { |row| csv << row.values_at(*headers) }
        end
        Success(path)
      rescue => err
        Failure(CMT::Failure.new(context: "#{name}.#{__callee__}",
          message: err.message))
      end

      def to_log(result, action)
        prefix = "#{log_prefix}#{vocab.source_code}|#{action}|"
        result.either(
          ->(success) { log.info("#{prefix}#{success}") },
          ->(failure) do
            add_error
            message = if failure.is_a?(String)
              failure
            elsif failure.is_a?(CollectionSpace::Response)
              "#{failure.status_code} #{failure.parsed}"
            else
              "UNHANDLED_FAILURE_TYPE: #{failure.inspect}"
            end
            log.error("#{prefix}#{message}")
          end
        )
      end
    end
  end
end
