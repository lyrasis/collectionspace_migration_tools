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
    CMT.config.term_manager.authority_sources[path] = "auth"
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
        terms = result.map { |r| r["termDisplayName"] }.sort
        expect(terms).to eq(["Education collection", "Museum collection"])
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

  describe "#delta" do
    let(:result) do
      vocab.delta(load_version).sort_by { |r| r["termDisplayName"] }
    end
    let(:terms) { result.map { |r| r["termDisplayName"] }.sort }
    let(:type) { "concept" }
    let(:subtype) { "ethfilecode" }

    context "when vocab has not been loaded" do
      let(:load_version) { nil }

      it "returns as expected" do
        expect(terms).to eq(["Education collection", "Museum collection"])
      end
    end

    context "when load_version equal to vocab_version" do
      let(:load_version) { 2 }

      it "returns as expected" do
        expect(result).to eq([])
      end
    end

    context "when load_version greater than vocab_version" do
      let(:load_version) { 4 }

      it "returns as expected" do
        expect(result).to eq([])
      end
    end

    context "when stuff gets complicated..." do
      let(:type) { "person" }
      let(:subtype) { "local" }

      context "when loading fresh" do
        let(:load_version) { nil }

        it "returns as expected" do
          expect(terms).to eq(%w[A Bcdef Ng Zy])
        end
      end

      context "when 0 to 10" do
        let(:load_version) { 0 }

        it "returns as expected" do
          expect(result.length).to eq(4)
          t0 = result[0]
          expect(t0["termDisplayName"]).to eq("A")
          expect(t0["loadAction"]).to eq("create")
          t1 = result[1]
          expect(t1["termDisplayName"]).to eq("Bcdef")
          expect(t1["loadAction"]).to eq("create")
          t2 = result[2]
          expect(t2["termDisplayName"]).to eq("Ng")
          expect(t2["loadAction"]).to eq("update")
          expect(t2["prevterm"]).to eq("N")
          t3 = result[3]
          expect(t3["termDisplayName"]).to eq("Zy")
          expect(t3["loadAction"]).to eq("update")
          expect(t3["prevterm"]).to eq("Z")
        end
      end

      context "when 1 to 10" do
        let(:load_version) { 1 }

        it "returns as expected" do
          expect(result.length).to eq(3)
          t0 = result[0]
          expect(t0["termDisplayName"]).to eq("Bcdef")
          expect(t0["loadAction"]).to eq("create")
          t1 = result[1]
          expect(t1["termDisplayName"]).to eq("Ng")
          expect(t1["loadAction"]).to eq("update")
          expect(t1["prevterm"]).to eq("N")
          t2 = result[2]
          expect(t2["termDisplayName"]).to eq("Zy")
          expect(t2["loadAction"]).to eq("update")
          expect(t2["prevterm"]).to eq("Z")
        end
      end

      context "when 3 to 10" do
        let(:load_version) { 3 }

        it "returns as expected" do
          expect(result.length).to eq(4)
          t0 = result[0]
          expect(t0["termDisplayName"]).to eq("A")
          expect(t0["loadAction"]).to eq("update")
          expect(t0["prevterm"]).to eq("Ab")
          t1 = result[1]
          expect(t1["termDisplayName"]).to eq("Bcdef")
          expect(t1["loadAction"]).to eq("update")
          expect(t1["prevterm"]).to eq("B")
          t2 = result[2]
          expect(t2["termDisplayName"]).to eq("Hi")
          expect(t2["loadAction"]).to eq("delete")
          expect(t2["prevterm"]).to eq("H")
          t3 = result[3]
          expect(t3["termDisplayName"]).to eq("Ng")
          expect(t3["loadAction"]).to eq("update")
          expect(t3["prevterm"]).to eq("N")
        end
      end

      context "when 4 to 10" do
        let(:load_version) { 4 }

        it "returns as expected" do
          expect(result.length).to eq(2)
          t0 = result[0]
          expect(t0["termDisplayName"]).to eq("A")
          expect(t0["loadAction"]).to eq("update")
          expect(t0["prevterm"]).to eq("Abc")
          t1 = result[1]
          expect(t1["termDisplayName"]).to eq("Hi")
          expect(t1["loadAction"]).to eq("delete")
          expect(t1["prevterm"]).to eq("H")
        end
      end
    end
  end
end
