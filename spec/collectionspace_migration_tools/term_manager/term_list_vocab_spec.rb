# frozen_string_literal: true

require_relative "../../spec_helper"

RSpec.describe CollectionspaceMigrationTools::TermManager::TermListVocab do
  before(:all) do
    ENV["COLLECTIONSPACE_MIGRATION_TOOLS_SYSTEM_CONFIG"] =
      File.join(fixtures_base, "sys_config_w_term_manager.yml")
  end

  before(:each) do
    CMT.reset_config
    CMT::TM::Project.new("napo").config
  end

  after(:all) do
    ENV.delete("COLLECTIONSPACE_MIGRATION_TOOLS_SYSTEM_CONFIG")
  end

  subject(:vocab) do
    path = File.join(fixtures_base, "shared_term_lists.xlsx")
    CMT.config.term_manager.term_list_sources << path
    src = CMT::TM::TermSource.new(path)
    src.vocabs.find { |vocab| vocab.vocabname == type }
  end

  describe "#init_load_mode" do
    let(:result) { vocab.init_load_mode }

    context "with default setting (additive)" do
      before(:each) do
        CMT.config.term_manager.initial_term_list_load_mode_overrides <<
          "newvocab"
      end

      context "with newvocab overriding main setting" do
        let(:type) { "newvocab" }

        it "returns exact" do
          expect(result).to eq("exact")
        end
      end

      context "with annotationtype not overridden" do
        let(:type) { "annotationtype" }

        it "returns additive" do
          expect(result).to eq("additive")
        end
      end
    end

    context "with init_load_mode = exact" do
      before(:each) do
        CMT.config.term_manager.initial_term_list_load_mode = "exact"
        CMT.config.term_manager.initial_term_list_load_mode_overrides <<
          "newvocab"
      end

      context "with newvocab overriding main setting" do
        let(:type) { "newvocab" }

        it "returns additive" do
          expect(result).to eq("additive")
        end
      end

      context "with annotationtype not overridden" do
        let(:type) { "annotationtype" }

        it "returns exact" do
          expect(result).to eq("exact")
        end
      end
    end
  end

  describe "#present_in_version?" do
    let(:result) { vocab.present_in_version?(load_version) }
    let(:type) { "newvocab" }

    context "when vocab added after last load" do
      let(:load_version) { 2 }

      it "returns false" do
        expect(result).to be false
      end
    end

    context "when vocab added in last load" do
      let(:load_version) { 4 }

      it "returns true" do
        expect(result).to be true
      end
    end

    context "when vocab added before last load" do
      let(:load_version) { 5 }

      it "returns true" do
        expect(result).to be true
      end
    end
  end

  describe "#current" do
    let(:result) { vocab.current }

    context "when objectcategory" do
      let(:type) { "objectcategory" }

      it "returns as expected" do
        expect(result).to be_a(Array)
        expect(result.length).to eq(18)
        terms = result.map { |r| r["displayName"] }
        expect(terms).not_to include("human remains")
        expect(terms).to include("human remains, unmodified")
      end
    end

    context "when publishto" do
      let(:type) { "publishto" }

      it "returns as expected" do
        expect(result).to be_a(Array)
        expect(result.length).to eq(2)
        terms = result.map { |r| r["displayName"] }
        expect(terms).not_to include("Omeka")
        expect(terms).to include("none")
      end
    end
  end

  describe "#delta" do
    let(:result) do
      vocab.delta(load_version).sort_by { |r| r["termDisplayName"] }
    end
    let(:terms) { result.map { |r| r["displayName"] }.sort }
    let(:type) { "objectcategory" }

    context "when vocab has not been loaded" do
      let(:load_version) { nil }

      it "returns as expected" do
        expected = ["debitage", "ethnographic", "faunal remains, modified",
          "faunal remains, unmodified", "floral remains, modified",
          "floral remains, unmodified", "historics",
          "human remains, commingled", "human remains, modified",
          "human remains, unmodified", "mineral, modified",
          "mineral, unmodified", "shell, modified",
          "shell, unmodified", "soil", "stone, modified",
          "stone, unmodified", "unidentified object"]
        expect(terms).to eq(expected)
      end
    end

    context "when load_version equal to vocab_version" do
      let(:load_version) { 3 }

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

    context "when 0 to 3" do
      let(:load_version) { 0 }

      it "returns as expected" do
        expect(result.length).to eq(13)
        t0 = result[0]
        expect(t0["displayName"]).to eq("human remains, unmodified")
        expect(t0["loadAction"]).to eq("update")
        expect(t0["prevterm"]).to eq("human remains")
      end
    end
  end
end
