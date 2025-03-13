# frozen_string_literal: true

require_relative "../../spec_helper"

RSpec.describe CollectionspaceMigrationTools::TermManager::TermSource do
  subject(:source) do
    CMT::TM::Project.new("napo").config
    described_class.new(path)
  end

  before(:all) do
    ENV["COLLECTIONSPACE_MIGRATION_TOOLS_SYSTEM_CONFIG"] =
      File.join(fixtures_base, "sys_config_w_term_manager.yml")
  end

  after(:all) do
    ENV.delete("COLLECTIONSPACE_MIGRATION_TOOLS_SYSTEM_CONFIG")
  end

  describe ".new" do
    let(:path) { "foo" }

    it "returns TermSource" do
      expect(source).to be_a(CMT::TM::TermSource)
    end
  end

  describe "#type" do
    let(:result) { source.type }

    context "when term list source" do
      let(:path) { CMT.config.term_manager.term_list_sources.first }

      it "returns as expected" do
        expect(result).to eq(:term_list)
      end
    end

    context "when term list source" do
      let(:path) { CMT.config.term_manager.authority_sources.first }

      it "returns as expected" do
        expect(result).to eq(:authority)
      end
    end
  end
end
