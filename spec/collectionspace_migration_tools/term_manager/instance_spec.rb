# frozen_string_literal: true

require_relative "../../spec_helper"

RSpec.describe CollectionspaceMigrationTools::TermManager::Instance do
  subject(:instance) do
    described_class.new(id, cfg)
  end

  let(:id) { "foo" }
  let(:cfg) { {} }

  before(:all) do
    ENV["COLLECTIONSPACE_MIGRATION_TOOLS_SYSTEM_CONFIG"] =
      File.join(fixtures_base, "sys_config_w_term_manager.yml")
  end

  after(:all) do
    ENV.delete("COLLECTIONSPACE_MIGRATION_TOOLS_SYSTEM_CONFIG")
  end

  describe ".new" do
    it "returns Instance" do
      expect(instance).to be_a(CMT::TM::Instance)
    end
  end

  describe "#client" do
    let(:result) { instance.client }
    let(:chia) { CHIA }
    let(:base_config) do
      {
        base_uri: "https://base.uri",
        username: "username",
        password: "pw"
      }
    end
    before do
      allow(chia).to receive(:client_config_for).and_return(base_config)
    end

    context "with no hardcoded config" do
      let(:id) { "vern" }

      it "returns config" do
        expect(result).to be_a(CollectionSpace::Client)
        expect(instance.send(:setup_config)).to eq(base_config)
      end
    end

    context "with partial hardcoded config" do
      let(:id) { "napo" }
      let(:cfg) do
        {base_uri: "https://napo.staging.collectionspace.org/cspace-services"}
      end

      it "returns config" do
        expected = {
          base_uri: "https://napo.staging.collectionspace.org/cspace-services",
          username: "username",
          password: "pw"
        }
        expect(result).to be_a(CollectionSpace::Client)
        expect(instance.send(:setup_config)).to eq(expected)
      end
    end

    context "with partial hardcoded config" do
      let(:id) { "munstead" }
      let(:cfg) do
        {
          base_uri: "https://munsteaaaaad.collectionspace.org/cspace-services",
          username: "myemail@lyrasis.org",
          password: "mypassword"
        }
      end

      it "returns config" do
        expect(result).to be_a(CollectionSpace::Client)
        expect(instance.send(:setup_config)).to eq(cfg)
      end
    end
  end
end
