# frozen_string_literal: true

require "dry/monads"

module CollectionspaceMigrationTools
  class RecordMapper
    include Dry::Monads[:result]

    attr_reader :to_h

    def initialize(hash)
      @to_h = hash
      @config = to_h["config"]
      @mappings = to_h["mappings"]
    end

    def authority? = service_type == "authority"

    def base_namespace
      config["ns_uri"].keys
        .find do |ns|
        ns.end_with?("_common") && (
          ns[type_label] || ns[service_path] || ns[document_name]
        )
      end
    end

    def db_term_group_table_name
      term_group_list_key.delete_suffix("List").downcase
    end

    def document_name = config["document_name"]

    def existence_check_method
      if object?
        :object_exists?
      elsif procedure?
        :procedure_exists?
      elsif authority?
        :auth_term_exists?
      elsif relation?
        :relation_exists?
      end
    end

    def name = config["mapper_name"]

    def object? = service_type == "object"

    def procedure? = service_type == "procedure"

    def id_field = config["identifier_field"]

    # @return [String] used for interacting directly with API
    def service_path_full
      return service_path unless authority?

      "#{service_path}/urn:cspace:name(#{subtype})/items"
    end

    def mappable_to_service_path
      return {config["recordtype"] => service_path_full} unless authority?

      {name => service_path_full}
    end

    def refname_columns
      mappings.select { |mapping| requires_refname?(mapping) }
    end

    def relation? = service_type == "relation"

    def type
      authority? ? config["authority_type"] : service_path
    end

    def type_subtype = [type_label, subtype].compact.join("_")

    def type_label = config["recordtype"]

    def search_field = config["search_field"]

    def subtype = config["authority_subtype"]

    # @return [String] base service path value defined for record type in UI
    #   config; used in database queries
    def service_path = config["service_path"]

    def service_path_to_mappable
      {service_path => config["recordtype"]}
    end

    def service_type = config["service_type"]

    def to_monad = Success(self)

    def to_s = "<##{self.class}:#{object_id.to_s(8)} #{config}>"

    def vocabs
      return {} unless authority?

      res = {}
      config["authority_subtypes"].each do |pair|
        res[pair["subtype"]] = pair["name"].downcase.tr(" ", "-")
      end
      res
    end

    private

    attr_reader :config, :mappings

    def requires_refname?(mapping)
      return false if mapping["data_type"] == "csrefname"
      source_type = mapping["source_type"]
      return true if source_type == "authority" || source_type == "vocabulary"

      false
    end

    def term_group_list_key
      to_h["docstructure"][base_namespace].keys
        .find { |key| key.end_with?("TermGroupList") }
    end
  end
end
