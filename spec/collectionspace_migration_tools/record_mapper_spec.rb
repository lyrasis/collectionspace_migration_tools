# frozen_string_literal: true

require "fileutils"
require_relative "../spec_helper"

RSpec.describe CollectionspaceMigrationTools::RecordMapper do
  let(:mapper) { described_class.new(hash) }
  let(:org_local_hash) do
    {"config" =>
     {"recordtype" => "organization",
      "document_name" => "organizations",
      "service_path" => "orgauthorities",
      "service_type" => "authority",
      "object_name" => "Organization",
      "ns_uri" =>
        {"organizations_common" =>
           "http://collectionspace.org/services/organization",
         "contacts_common" => "http://collectionspace.org/services/contact"},
      "identifier_field" => "shortIdentifier",
      "search_field" => "organizationTermGroupList/0/termDisplayName",
      "authority_subtypes" =>
        [{"name" => "Local", "subtype" => "organization"},
          {"name" => "ULAN", "subtype" => "ulan_oa"}],
      "authority_type" => "orgauthorities",
      "authority_subtype" => "organization"},
     "docstructure" => {
       "organizations_common" => {
         "orgTermGroupList" => {
           "orgTermGroup" => {}
         }
       }
     }}
  end
  let(:person_ulan_hash) do
    {"config" =>
     {"profile_basename" => "core",
      "version" => "7-0-0",
      "recordtype" => "person",
      "document_name" => "persons",
      "service_name" => "Persons",
      "service_path" => "personauthorities",
      "service_type" => "authority",
      "object_name" => "Person",
      "ns_uri" =>
        {"persons_common" => "http://collectionspace.org/services/person",
         "contacts_common" => "http://collectionspace.org/services/contact"},
      "identifier_field" => "shortIdentifier",
      "search_field" => "personTermGroupList/0/termDisplayName",
      "authority_subtypes" =>
        [{"name" => "Local", "subtype" => "person"},
          {"name" => "ULAN", "subtype" => "ulan_pa"}],
      "authority_type" => "personauthorities",
      "authority_subtype" => "ulan_pa"},
     "docstructure" =>
     {"persons_common" =>
      {"personTermGroupList" => {"personTermGroup" => {}},
       "occupations" => {},
       "schoolsOrStyles" => {},
       "groups" => {},
       "nationalities" => {}}}}
  end
  let(:taxon_local_hash) do
    {"config" =>
     {"profile_basename" => "anthro",
      "version" => "5-0-0",
      "recordtype" => "taxon",
      "document_name" => "taxon",
      "service_name" => "Taxon",
      "service_path" => "taxonomyauthority",
      "service_type" => "authority",
      "object_name" => "Taxon",
      "ns_uri" => {
        "taxon_common" => "http://collectionspace.org/services/taxonomy"
      },
      "identifier_field" => "shortIdentifier",
      "search_field" => "taxonTermGroupList/0/termDisplayName",
      "authority_subtypes" =>
        [{"name" => "Local", "subtype" => "taxon"},
          {"name" => "Common", "subtype" => "common_ta"}],
      "authority_type" => "taxonomyauthority",
      "authority_subtype" => "taxon"},
     "docstructure" =>
     {"taxon_common" =>
      {"taxonTermGroupList" => {"taxonTermGroup" => {}},
       "taxonAuthorGroupList" => {"taxonAuthorGroup" => {}},
       "taxonCitationList" => {},
       "commonNameGroupList" => {"commonNameGroup" => {}}}}}
  end

  context "with person authority" do
    let(:hash) { person_ulan_hash }
    describe "#authority?" do
      it "returns true" do
        expect(mapper.authority?).to be true
      end
    end

    describe "#base_namespace" do
      it "returns persons_common" do
        expect(mapper.base_namespace).to eq("persons_common")
      end
    end

    describe "#db_term_group_table_name" do
      it "returns persontermgroup" do
        expect(mapper.db_term_group_table_name).to eq("persontermgroup")
      end
    end

    describe "#type" do
      it "returns personauthorities" do
        expect(mapper.type).to eq("personauthorities")
      end
    end

    describe "#type_subtype" do
      it "returns person_ulan_pa" do
        expect(mapper.type_subtype).to eq("person_ulan_pa")
      end
    end

    describe "#type_label" do
      it "returns person" do
        expect(mapper.type_label).to eq("person")
      end
    end

    describe "#subtype" do
      it "returns ulan_pa" do
        expect(mapper.subtype).to eq("ulan_pa")
      end
    end

    describe "#service_path" do
      it "returns personauthorities" do
        expect(mapper.service_path).to eq("personauthorities")
      end
    end
  end

  context "with org local authority" do
    let(:hash) { org_local_hash }
    describe "#authority?" do
      it "returns true" do
        expect(mapper.authority?).to be true
      end
    end

    describe "#base_namespace" do
      it "returns expected" do
        expect(mapper.base_namespace).to eq("organizations_common")
      end
    end

    describe "#db_term_group_table_name" do
      it "returns expected" do
        expect(mapper.db_term_group_table_name).to eq("orgtermgroup")
      end
    end

    describe "#type" do
      it "returns expected" do
        expect(mapper.type).to eq("orgauthorities")
      end
    end

    describe "#type_subtype" do
      it "returns expected" do
        expect(mapper.type_subtype).to eq("organization_organization")
      end
    end

    describe "#type_label" do
      it "returns expected" do
        expect(mapper.type_label).to eq("organization")
      end
    end

    describe "#subtype" do
      it "returns expected" do
        expect(mapper.subtype).to eq("organization")
      end
    end

    describe "#service_path" do
      it "returns expected" do
        expect(mapper.service_path).to eq("orgauthorities")
      end
    end
  end

  context "with taxon local authority" do
    let(:hash) { taxon_local_hash }
    describe "#authority?" do
      it "returns true" do
        expect(mapper.authority?).to be true
      end
    end

    describe "#base_namespace" do
      it "returns expected" do
        expect(mapper.base_namespace).to eq("taxon_common")
      end
    end

    describe "#db_term_group_table_name" do
      it "returns expected" do
        expect(mapper.db_term_group_table_name).to eq("taxontermgroup")
      end
    end

    describe "#type" do
      it "returns expected" do
        expect(mapper.type).to eq("taxonomyauthority")
      end
    end

    describe "#type_subtype" do
      it "returns expected" do
        expect(mapper.type_subtype).to eq("taxon_taxon")
      end
    end

    describe "#type_label" do
      it "returns expected" do
        expect(mapper.type_label).to eq("taxon")
      end
    end

    describe "#subtype" do
      it "returns expected" do
        expect(mapper.subtype).to eq("taxon")
      end
    end

    describe "#service_path" do
      it "returns expected" do
        expect(mapper.service_path).to eq("taxonomyauthority")
      end
    end
  end

  context "with collectionobject" do
    let(:hash) do
      {
        "config" => {
          "recordtype" => "collectionobject",
          "service_type" => "object",
          "service_path" => "collectionobjects",
          "ns_uri" => {
            "collectionobjects_annotation" =>
              "http://collectionspace.org/services/collectionobject/"\
              "domain/annotation",
            "collectionobjects_common" =>
              "http://collectionspace.org/services/collectionobject"
          }
        }
      }
    end

    describe "#authority?" do
      it "returns false" do
        expect(mapper.authority?).to be false
      end
    end

    describe "#base_namespace" do
      it "returns collectionobjects_common" do
        expect(mapper.base_namespace).to eq("collectionobjects_common")
      end
    end

    describe "#type" do
      it "returns collectionobjects" do
        expect(mapper.type).to eq("collectionobjects")
      end
    end

    describe "#object?" do
      it "returns true" do
        expect(mapper.object?).to be true
      end
    end

    describe "#procedure?" do
      it "returns false" do
        expect(mapper.procedure?).to be false
      end
    end

    describe "#type_subtype" do
      it "returns collectionobject" do
        expect(mapper.type_subtype).to eq("collectionobject")
      end
    end

    describe "#type_label" do
      it "returns collectionobject" do
        expect(mapper.type_label).to eq("collectionobject")
      end
    end

    describe "#subtype" do
      it "returns nil" do
        expect(mapper.subtype).to be_nil
      end
    end

    describe "#service_path" do
      it "returns collectionobjects" do
        expect(mapper.service_path).to eq("collectionobjects")
      end
    end
  end
end
