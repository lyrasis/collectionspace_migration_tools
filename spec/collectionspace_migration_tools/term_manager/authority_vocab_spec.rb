# frozen_string_literal: true

require_relative "../../spec_helper"

RSpec.describe CollectionspaceMigrationTools::TermManager::AuthorityVocab do
  before(:all) do
    ENV["COLLECTIONSPACE_MIGRATION_TOOLS_SYSTEM_CONFIG"] =
      File.join(fixtures_base, "sys_config_w_term_manager.yml")
    CMT.reset_config
  end

  after(:all) do
    ENV.delete("COLLECTIONSPACE_MIGRATION_TOOLS_SYSTEM_CONFIG")
  end

  subject(:vocab) do
    path = File.join(fixtures_base, "shared_authorities.xlsx")
    CMT::TM::Project.new("napo").config
    CMT.config.term_manager.authority_sources << path
    src = CMT::TM::TermSource.new(path)
    src.vocabs.find { |vocab| vocab.type == type && vocab.subtype == subtype }
  end

  describe "#current" do
    let(:result) { vocab.current }

    context "when concept/material" do
      let(:type) { "concept" }
      let(:subtype) { "material" }

      it "returns as expected" do
        expect(result).to be_a(Array)
        expect(result.length).to eq(6)
        terms = result.map { |r| r["termDisplayName"] }
        expect(terms).not_to include("rubber")
        expect(terms).to include("natural rubber")
      end
    end

    context "when concept/ethfilecode" do
      let(:type) { "concept" }
      let(:subtype) { "ethfilecode" }

      it "returns as expected" do
        expect(result).to be_a(Array)
        expect(result.length).to eq(2)
        terms = result.map { |r| r["termDisplayName"] }
        expect(terms).not_to include("Archaeologically recovered teaching "\
                                     "collection")
        expect(terms).to include("Museum collection")
        expect(terms).to include("Education collection")
      end
    end
  end

  describe "#vocab_version" do
    let(:result) { vocab.vocab_version }

    context "when concept/material" do
      let(:type) { "concept" }
      let(:subtype) { "material" }

      it "returns as expected" do
        expect(result).to eq(1)
      end
    end

    context "when concept/ethfilecode" do
      let(:type) { "concept" }
      let(:subtype) { "ethfilecode" }

      it "returns as expected" do
        expect(result).to eq(2)
      end
    end
  end
end
