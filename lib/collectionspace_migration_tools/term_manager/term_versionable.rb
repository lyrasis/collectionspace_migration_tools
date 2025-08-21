# frozen_string_literal: true

module CollectionspaceMigrationTools
  module TermManager
    # Mixin containing logic for identifying most-recent terms for a vocab
    #   and deltas between versions of a vocab
    module TermVersionable
      def not_yet_loaded?(load_version) = last_load_rows(load_version).empty?

      # @return [Array<Hash>] rows to load if starting from scratch
      def current(rowset = rows)
        rowset.group_by { |r| r["id"] }
          .map { |_id, vrows| select_current(vrows) }
          .reject { |r| r["loadAction"] == "delete" }
      end

      # @param load_version [Integer, nil] last loaded term source version
      # @return [Array<Hash>] rows to load to update since last load
      def delta(load_version)
        return current.map { |t| clean_term(t) } unless load_version
        return [] if load_version >= vocab_version

        raw_delta = rows_since_load(load_version)
          .group_by { |r| r["id"] }
          .map { |_id, vrows| select_current(vrows) }

        prev = last_load_rows(load_version)

        raw_delta.map { |term| prep_delta_term(term, prev) }
          .compact
          .map { |t| clean_term(t) }
      end

      def vocab_version
        @vocab_version ||= rows.map { |row| row["loadVersion"].to_i }
          .max
      end

      def work_plan(load_version, client)
        todo = delta(load_version)
        return nil if todo.empty?

        plan = {vocab_type: vocab_type, vocab_name: vocabname, rows: todo}
        status = not_yet_loaded?(load_version) ? :initial : :subsequent
        plan[:term_list_status] = status
        return plan unless vocab_type == "term list" && status == :initial

        plan[:init_load_mode] = init_load_mode
        return plan unless init_load_mode == "exact"

        exact_deletes = get_exact_deletes(todo, client, vocabname)
        return plan if exact_deletes.empty?

        plan[:rows] = todo + exact_deletes
        plan
      end

      # @return [Array<String>] field names related to versioning
      def version_fields = %w[loadVersion loadAction id prevterm origterm
        sort-dedupe]

      private

      def get_exact_deletes(todo, client, vocabname)
        adding = todo.map { |t| t["term"] }
        svc_path = CollectionSpace::Service.get(
          type: "vocabularies", subtype: vocabname
        )[:path]
        existing = client.all(svc_path)
          .map { |t| t["displayName"] }
          .to_a
        deleting = existing - adding
        return [] if deleting.empty?

        deleting.map { |t| create_exact_delete(t, todo.first) }
      end

      def create_exact_delete(t, example)
        {
          "loadAction" => "delete",
          "term_list_displayName" => example["term_list_displayName"],
          "term_list_shortIdentifier" => example["term_list_shortIdentifier"],
          "term" => t,
          "origterm" => t
        }
      end

      def clean_term(term)
        %w[loadVersion id sort-dedupe].each { |key| term.delete(key) }
        term
      end

      def select_current(vrows)
        return vrows.first if vrows.length == 1

        vrows.max_by { |r| r["loadVersion"].to_i }
      end

      def rows_since_load(load_version)
        rows.reject { |row| row["loadVersion"] <= load_version }
      end

      def last_load_rows(load_version)
        return [] unless load_version

        current(rows.select { |row| row["loadVersion"] <= load_version })
      end

      def prep_delta_term(term, prev)
        prev_term = previous(term, prev)

        case term["loadAction"]
        when "create"
          prep_delta_create(term, prev_term)
        when "update"
          prep_delta_update(term, prev_term)
        when "delete"
          prep_delta_delete(term, prev_term)
        end
      end

      def prep_delta_create(term, prev_term)
        return cleaned_create_term(term) unless prev_term
        return if same_term?(term, prev_term)

        term["loadAction"] = "update"
        term["prevterm"] = term_id(prev_term)
        cleaned_update_term(term)
      end

      def cleaned_create_term(term)
        term.delete("origterm")
        term.compact
      end

      def cleaned_update_term(term)
        term.delete("origterm")
        term.compact
      end

      def prep_delta_update(term, prev_term)
        return if prev_term && same_term?(term, prev_term)

        if prev_term
          term["prevterm"] = term_id(prev_term)
          cleaned_update_term(term)
        else
          term["loadAction"] = "create"
          cleaned_create_term(term)
        end
      end

      def prep_delta_delete(term, prev_term)
        return unless prev_term

        term["prevterm"] = term_id(prev_term)
        cleaned_update_term(term)
      end

      def previous(term, prev) = prev.find do |row|
        row["origterm"] == term["origterm"]
      end

      def same_term?(term, prev_term)
        cleaned = [term, prev_term].map { |trm| content_fields(trm) }
        cleaned.first == cleaned.last
      end

      def term_id(prev_term) = prev_term[term_field_name].split("|").first

      def content_fields(trm)
        term = trm.dup
        term.delete_if { |field, _val| version_fields.include?(field) }
      end
    end
  end
end
