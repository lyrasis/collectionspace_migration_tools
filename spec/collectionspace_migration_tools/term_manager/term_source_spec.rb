# frozen_string_literal: true

require_relative "../../spec_helper"

RSpec.describe CollectionspaceMigrationTools::TermManager::TermSource do
  subject(:source) { described_class.new(path) }

  let(:bad_path) { "foo" }
  let(:termlist_path) { File.join(fixtures_base, "shared_term_lists.xlsx") }
  let(:authority_path) { File.join(fixtures_base, "shared_authorities.xlsx") }

  before(:all) do
    ENV["COLLECTIONSPACE_MIGRATION_TOOLS_SYSTEM_CONFIG"] =
      File.join(fixtures_base, "sys_config_w_term_manager.yml")
    CMT.reset_config
  end

  after(:all) do
    ENV.delete("COLLECTIONSPACE_MIGRATION_TOOLS_SYSTEM_CONFIG")
  end

  describe ".new" do
    let(:path) { bad_path }

    it "returns TermSource" do
      expect(source).to be_a(CMT::TM::TermSource)
    end
  end

  describe "#workbook" do
    let(:result) do
      CMT::TM::Project.new("napo").config
      source.workbook
    end

    context "with non-existent path" do
      let(:path) { bad_path }

      it "returns nil" do
        expect(result).to be_nil
      end
    end

    context "with good path" do
      let(:path) { termlist_path }

      it "returns Roo::Excelx" do
        expect(result).to be_a(Roo::Excelx)
      end
    end
  end

  describe "#type" do
    let(:result) do
      CMT::TM::Project.new("napo").config
      source.type
    end

    context "when term list source" do
      let(:path) { CMT.config.term_manager.term_list_sources.first }

      it "returns as expected" do
        expect(result).to eq(:term_list)
      end
    end

    context "when authority source" do
      let(:path) { CMT.config.term_manager.authority_sources.keys.first }

      it "returns as expected" do
        expect(result).to eq(:authority)
      end
    end
  end

  describe "#sheet" do
    before(:each) do
      CMT::TM::Project.new("napo").config
      CMT.config.term_manager.term_list_sources << path
    end
    let(:path) { termlist_path }
    let(:result) { source.sheet }

    it "returns as expected" do
      expect(result).to be_a(Roo::Excelx)
    end
  end

  describe "#current_version" do
    before(:each) do
      CMT::TM::Project.new("napo").config
      CMT.config.term_manager.term_list_sources << path
    end
    let(:path) { authority_path }
    let(:result) { source.current_version }

    it "returns as expected" do
      expect(result).to eq(10)
    end
  end

  describe "#rows" do
    let(:path) { termlist_path }

    let(:result) do
      CMT::TM::Project.new("napo").config
      CMT.config.term_manager.term_list_sources << path
      described_class.new(path).rows
    end

    it "returns as expected" do
      expect(result).to be_a(Array)
      expect(result.first).to be_a(Hash)
    end
  end

  describe "#vocabs" do
    let(:result) { described_class.new(path).vocabs }

    context "when authority source" do
      before(:each) do
        CMT::TM::Project.new("napo").config
        CMT.config.term_manager.authority_sources[path] = "auth"
      end

      let(:path) { authority_path }

      it "returns as expected" do
        expect(result).to be_a(Array)
        expect(result.first).to be_a(CMT::TM::AuthorityVocab)
        expect(result.first.source_code).to eq("auth")
      end
    end

    context "when termlist source" do
      before(:each) do
        CMT::TM::Project.new("napo").config
        CMT.config.term_manager.term_list_sources << path
      end

      let(:path) { termlist_path }

      it "returns as expected" do
        expect(result).to be_a(Array)
        expect(result.first).to be_a(CMT::TM::TermListVocab)
      end
    end
  end
end
