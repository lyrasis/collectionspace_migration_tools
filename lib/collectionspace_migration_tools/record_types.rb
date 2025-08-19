# frozen_string_literal: true

require "dry/monads"

module CollectionspaceMigrationTools
  module RecordTypes
    extend Dry::Monads[:result, :do]

    module_function

    def alt_auth_rectype_form(rectype)
      splitdata = rectype.split("-")
      type = splitdata.shift
      subtype = splitdata.join("-")
      subtype = "field_collection" if subtype == "fieldcollection"

      newtype = if service_path_to_mappable_type_mapping.key?(type)
        service_path_to_mappable_type_mapping[type]
      else
        type
      end

      newsubtype = if authority_subtype_machine_to_human_label_mapping.key?(
        subtype
      )
        authority_subtype_machine_to_human_label_mapping[subtype]
      else
        subtype
      end

      result = [newtype, newsubtype].join("-")
      mappable.any?(result) ? Success(result) : Failure()
    end

    def authorities
      mappable.select { |rectype| rectype["-"] }
    end

    def authority_subtype_machine_to_human_label_mapping
      @authority_subtype_machine_to_human_label_mapping ||=
        get_authority_subtype_machine_to_human_label_mapping
    end

    def get_authority_subtype_machine_to_human_label_mapping
      # Since each authority vocabulary record mapper lists all vocabs
      #   for that authority, we just take one per authority
      authorities.map { |rectype| [rectype.split("-").first, rectype] }
        .to_h
        .values
        .map { |rectype| CMT::Parse::RecordMapper.call(rectype).value!.vocabs }
        .inject({}, :merge)
    end

    def get_service_path_to_mappable_type_mapping
      mappable.map do |rectype|
        CMT::Parse::RecordMapper.call(rectype).value!.service_path_to_mappable
      end
        .inject({}, :merge)
    end

    def get_mappable_type_to_service_path_mapping
      mappable.map do |rectype|
        CMT::Parse::RecordMapper.call(rectype).value!.mappable_to_service_path
      end
        .inject({}, :merge)
        .merge({"blob" => "blobs"})
    end

    def mappable
      @mappable ||= Dir.new(CMT.config.client.mapper_dir)
        .children
        .map do |fn|
          fn.delete_prefix(
            "#{CMT.config.client.profile}_#{CMT.config.client.profile_version}_"
          )
        end
        .map { |fn| fn.delete_suffix(".json") }
        .sort
    end

    def mappable?(str)
      mappable.any?(str)
    end

    def object
      "collectionobject"
    end

    def relations
      %w[authorityhierarchy nonhierarchicalrelationship
        objecthierarchy].select do |name|
        mappable.any?(name)
      end
    end

    def procedures
      mappable.reject { |name| name["-"] || name == object }
        .reject { |name| relations.any?(name) }
    end

    def service_path_to_mappable_type_mapping
      @service_path_to_mappable_type_mapping ||=
        get_service_path_to_mappable_type_mapping
    end

    # @param rectype [String]
    def services_api_path(rectype)
      if rectype == "vocabulary"
        result = CMT::Entity::Vocabulary.services_api_path
        return Success(result)
      end

      result = mappable_type_to_service_path_mapping[rectype]
    rescue => err
      msg = "#{err.message} IN #{err.backtrace[0]}"
      Failure(CMT::Failure.new(
        context: "#{name}.#{__callee__}", message: msg
      ))
    else
      return Success(result) if result

      msg = "No services path found for `#{rectype}`"
      Failure(CMT::Failure.new(
        context: "#{name}.#{__callee__}", message: msg
      ))
    end

    def mappable_type_to_service_path_mapping
      @mappable_type_to_service_path_mapping ||=
        get_mappable_type_to_service_path_mapping
    end

    def to_obj(rectype)
      rt = yield valid_mappable(rectype)

      return Success(CMT::Entity::Vocabulary.new) if rt == "vocabulary"

      if rt == "collectionobject"
        return Success(CMT::Entity::Collectionobject.new)
      end
      if relations.any?(rt)
        return Success(CMT::Entity::Relation.new(rt))
      end
      if procedures.any?(rt)
        return Success(CMT::Entity::Procedure.new(rt))
      end
      if authorities.any?(rt)
        return Success(CMT::Entity::Authority.from_str(rt))
      end

      Failure("#{rectype} cannot be converted to a CMT CS Entity object")
    end

    def valid_mappable(rectype)
      return Success(rectype) if rectype == "vocabulary" ||
        mappable.any?(rectype)

      alt_auth_rectype_form(rectype).bind do |alt_form|
        return Success(alt_form) if authorities.any?(alt_form)
      end

      Failure("Invalid rectype: #{rectype}. Do `thor rt:all` to see allowed "\
              "values")
    end
  end
end
