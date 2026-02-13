# frozen_string_literal: true

require_relative "../../spec_helper"

RSpec.describe CollectionspaceMigrationTools::Config::Client do
  let(:result) do
    described_class.call(hash: config_hash)
  end

  context "when valid config" do
    let(:config_hash) { valid_config_hash[:client] }

    it "returns Success" do
      expect(result).to be_a(Dry::Monads::Success)
      expect(result.value!.cs_app_version).to be_nil
    end
  end

  context "when optional cs_app_version given" do
    let(:config_hash) do
      h = valid_config_hash[:client]
      h.merge!({cs_app_version: "1_2"})
    end

    it "returns Success" do
      expect(result).to be_a(Dry::Monads::Success)
      expect(result.value!.cs_app_version).to eq("1_2")
    end
  end

  context "when malformed optional cs_app_version given" do
    let(:config_hash) do
      h = valid_config_hash[:client]
      h.merge!({cs_app_version: "1.2"})
    end

    it "returns Failure" do
      expect(result).to be_a(Dry::Monads::Failure)
    end
  end

  context "when valid hosted client config" do
    let(:config_hash) do
      path = File.join(fixtures_base, "hosted_client_config_valid.yml")
      CMT::Parse::YamlConfig.call(path).value![:client]
    end

    it "returns Success" do
      mock_site = double("Site",
        services_url: "https://ohiohistory.collectionspace.org/cspace-services",
        user_name: "admin@collectionspace.org",
        admin_password: "abcdefgh",
        db_host: "hostname",
        db_user_name: "admin",
        db_password: "pw",
        db_name: "name_name")

      allow(CHIA).to receive(:site_for) { mock_site }
      expect(result).to be_a(Dry::Monads::Success)
    end
  end
end
