# frozen_string_literal: true

require "dry/monads"

module CollectionspaceMigrationTools
  module Rels
    # Salient NHR info from CSV row, and relevant behavior for looking up NHRs
    class Nhr
      include Dry::Monads[:result]

      # @param row [Hash] with String keys
      # @param client [CollectionSpace::Client]
      def initialize(row, client)
        @client = client
        @id1 = row["item1_id"]
        @type1 = row["item1_type"]
        @id2 = row["item2_id"]
        @type2 = row["item2_type"]
      end

      # @param sub [1, 2]
      # @param obj [1, 2]
      def check_dir(sub, obj)
        dir = "#{sub} -> #{obj}"
        subjectcsid = send(:"csid#{sub}")
        objectcsid = send(:"csid#{obj}")

        item_errs = [subjectcsid, objectcsid].to_h do |n|
          [n, n.respond_to?(:failure)]
        end

        if item_errs.keys.any? { |n| n == true }
          return dir_item_error(dir, subjectcsid, objectcsid)
        end

        rel = get_rel(subjectcsid, objectcsid)

        if rel.respond_to?(:failure)
          return rel_error(dir, subjectcsid, objectcsid, rel)
        end

        rel_hash(dir, subjectcsid, objectcsid, rel)
      end

      private

      attr_reader :client, :id1, :id2, :type1, :type2

      # @param [1, 2]
      # @return [String, Dry::Monads::Failure]
      def get_csid(num)
        id = send(:"id#{num}")
        type = send(:"type#{num}")

        response = client.find(type: type, value: id)
        unless response.result.ok?
          return Failure("API call to look up #{type} #{id} failed: "\
                         "#{response.status_code}")
        end

        items = response.parsed.dig("abstract_common_list", "totalItems").to_i
        if items == 0
          return Failure("#{type} #{id} not found")
        end

        if items > 1
          return Failure("More than one record for #{type} #{id} found")
        end

        response.parsed.dig("abstract_common_list", "list_item", "csid")
      rescue KeyError
        Failure("Unrecognized item type: #{type}")
      end

      # @return (see #get_csid)
      def csid1 = @csid1 ||= get_csid(1)

      # @return (see #get_csid)
      def csid2 = @csid2 ||= get_csid(2)

      def dir_item_error(dir, subjectcsid, objectcsid)
        base = {"direction" => dir}
        errs = []
        %w[subjectcsid objectcsid].each do |n|
          val = send(n.to_sym)
          if val.respond_to?(:failure)
            errs << val.failure
          else
            base[n] = val
          end
        end
        base["check_err"] = errs.join("; ")
        base
      end

      def rel_error(dir, subjectcsid, objectcsid, rel)
        base = {"direction" => dir}
        %w[subjectcsid objectcsid].each do |n|
          val = send(n.to_sym)
          base[n] = val
        end
        base["check_err"] = rel.failure
        base
      end

      def get_rel(subjectcsid, objectcsid)
        response = client.find_relation(
          subject_csid: subjectcsid,
          object_csid: objectcsid,
          rel_type: "affects"
        )

        unless response.result.ok?
          return Failure("API call to look up relation failed: "\
                         "#{response.status_code}")
        end

        response.parsed
      end

      def rel_hash(dir, subjectcsid, objectcsid, rel)
        base = {
          "direction" => dir,
          "subjectcsid" => subjectcsid,
          "objectcsid" => objectcsid
        }

        items = rel.dig("relations_common_list", "totalItems").to_i
        base["exists"] = if items == 0
          "n"
        else
          "y"
        end

        if items == 1
          base["relcsid"] = rel.dig("relations_common_list",
            "relation_list_item",
            "csid")
        elsif items > 1
          raise("Unhandled relation lookup response")
        end

        base
      end
    end
  end
end
