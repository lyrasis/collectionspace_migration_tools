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
