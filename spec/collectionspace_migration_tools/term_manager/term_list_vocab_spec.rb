# frozen_string_literal: true

require_relative "../../spec_helper"

RSpec.describe CollectionspaceMigrationTools::TermManager::TermListVocab do
  before(:all) do
    ENV["COLLECTIONSPACE_MIGRATION_TOOLS_SYSTEM_CONFIG"] =
      File.join(fixtures_base, "sys_config_w_term_manager.yml")
    CMT.reset_config
  end

  after(:all) do
    ENV.delete("COLLECTIONSPACE_MIGRATION_TOOLS_SYSTEM_CONFIG")
  end

  subject(:vocab) do
    path = File.join(fixtures_base, "shared_term_lists.xlsx")
    CMT::TM::Project.new("napo").config
    CMT.config.term_manager.term_list_sources << path
    src = CMT::TM::TermSource.new(path)
    src.vocabs.find { |vocab| vocab.vocabname == type }
  end

  describe "#current" do
    let(:result) { vocab.current }

    context "when objectcategory" do
      let(:type) { "objectcategory" }

      it "returns as expected" do
        expect(result).to be_a(Array)
        expect(result.length).to eq(18)
        terms = result.map { |r| r["term"] }
        expect(terms).not_to include("human remains")
        expect(terms).to include("human remains, unmodified")
      end
    end

    context "when publishto" do
      let(:type) { "publishto" }

      it "returns as expected" do
        expect(result).to be_a(Array)
        expect(result.length).to eq(2)
        terms = result.map { |r| r["term"] }
        expect(terms).not_to include("Omeka")
        expect(terms).to include("none")
      end
    end
  end
end
