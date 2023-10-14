# frozen_string_literal: true

require_relative "../../spec_helper"

RSpec.describe CollectionspaceMigrationTools::Batch::CsidCacheDependencyIdentifier do
  let(:klass) { described_class.new(path: path, mapper: mapper) }

  describe "#call" do
    let(:result) { klass.call }

    context "when acquisition" do
      let(:path) { "foo" }
      let(:mapper) { CMT::Parse::RecordMapper.call("acquisition").value! }

      it "returns expected", :aggregate_failures do
        expect(result).to be_a(Dry::Monads::Success)
        expect(result.value!).to eq("acquisition")
      end
    end

    context "when objecthierarchy" do
      let(:path) { "foo" }
      let(:mapper) { CMT::Parse::RecordMapper.call("objecthierarchy").value! }

      it "returns expected", :aggregate_failures do
        expect(result).to be_a(Dry::Monads::Success)
        expect(result.value!).to eq("objecthierarchy|collectionobject")
      end
    end

    context "when authorityhierarchy" do
      let(:path) do
        File.join(Bundler.root, "spec", "support", "fixtures",
          "ah_csid_dep_test.csv")
      end
      let(:mapper) do
        CMT::Parse::RecordMapper.call("authorityhierarchy").value!
      end

      it "returns expected", :aggregate_failures do
        expect(result).to be_a(Dry::Monads::Success)
        expected = "authorityhierarchy|citation-local|citation-worldcat|concept-activity|concept-associated|location-local|location-offsite|organization-local|organization-ulan|person-local|person-ulan|place-local|place-tgn|work-cona|work-local"
        expect(result.value!).to eq(expected)
      end
    end

    context "when nonhierarchicalrelationship" do
      let(:path) do
        File.join(Bundler.root, "spec", "support", "fixtures",
          "nhr_csid_dep_test.csv")
      end
      let(:mapper) do
        CMT::Parse::RecordMapper.call("nonhierarchicalrelationship").value!
      end

      it "returns expected", :aggregate_failures do
        expect(result).to be_a(Dry::Monads::Success)
        expected = "acquisition|collectionobject|exhibition|group|loanin|nonhierarchicalrelationship"
        expect(result.value!).to eq(expected)
      end
    end
  end
end
