# frozen_string_literal: true

require_relative "../../spec_helper"

RSpec.describe CollectionspaceMigrationTools::Entity::Authority do
  subject(:auth) { described_class.from_str(str) }

  describe ".from_str" do
    context "valid rectype with slash" do
      let(:str) { "person/local" }

      it "constructs as expected" do
        expect(auth).to be_a(described_class)
        expect(auth.type).to eq("person")
        expect(auth.subtype).to eq("local")
        expect(auth.status.success?).to be true
        expect(auth.service_path).to eq("personauthorities")
        expect(auth.service_path_full).to eq(
          "personauthorities/urn:cspace:name(person)/items"
        )
      end
    end

    context "valid rectype with hyphen" do
      let(:str) { "person-local" }

      it "constructs as expected" do
        expect(auth).to be_a(described_class)
        expect(auth.type).to eq("person")
        expect(auth.subtype).to eq("local")
        expect(auth.status.success?).to be true
      end
    end

    context "invalid rectype" do
      let(:str) { "person" }

      it "constructs as expected" do
        expect(auth).to be_a(described_class)
        expect(auth.type).to eq("person")
        expect(auth.subtype).to eq("")
        expect(auth.status.failure?).to be true
      end
    end
  end

  describe "#cacheable_data_query" do
    let(:str) { "person/local" }
    let(:result) { auth.cacheable_data_query }

    it "returns as expected" do
      expect(result.value!).to match(/select 'personauthorities' as type,/)
    end
  end
end
