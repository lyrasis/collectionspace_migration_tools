# frozen_string_literal: true

require_relative "../../spec_helper"

RSpec.describe CollectionspaceMigrationTools::TermManager::Project do
  subject(:project) do
    described_class.new("napo")
  end

  before(:all) do
    ENV["COLLECTIONSPACE_MIGRATION_TOOLS_SYSTEM_CONFIG"] =
      File.join(fixtures_base, "sys_config_w_term_manager.yml")
    CMT.reset_config
  end

  after(:all) do
    ENV.delete("COLLECTIONSPACE_MIGRATION_TOOLS_SYSTEM_CONFIG")
  end

  describe ".new" do
    it "returns Project" do
      expect(project).to be_a(CMT::TM::Project)
    end
  end

  describe "#config" do
    let(:result) { project.config }

    it "returns as expected" do
      expect(result).to be_a(Struct)
      expect(CMT.config.term_manager).to be_a(Struct)
    end
  end

  describe "#instances" do
    let(:result) { project.instances }

    it "returns as expected" do
      expect(result).to be_a(Array)
      expect(result.first).to be_a(CMT::TM::Instance)
    end
  end

  describe "#term_sources" do
    let(:result) { project.term_sources }

    it "returns as expected" do
      expect(result).to be_a(Array)
      expect(result.first).to be_a(CMT::TM::TermSource)
    end
  end

  describe "#version_log" do
    let(:result) { project.version_log }

    it "returns as expected" do
      expect(result).to be_a(CMT::TM::VersionLog)
    end
  end

  describe "#run_log" do
    let(:result) { project.run_log }

    it "returns as expected" do
      expect(result).to be_a(Logger)
    end
  end
end
