# frozen_string_literal: true

require_relative "../../spec_helper"

RSpec.describe CollectionspaceMigrationTools::Config::Client do
  let(:result) do
    described_class.call(hash: config_hash, context: sysconfig)
  end

  let(:sysconfig) { nil }

  context "when valid config" do
    let(:config_hash) { valid_config_hash[:client] }

    it "returns Success" do
      expect(result).to be_a(Dry::Monads::Success)
      expect(result.value!.cs_app_version).to be_nil
    end
  end

  context "without optional mapper_dir" do
    before do
      ENV["COLLECTIONSPACE_MIGRATION_TOOLS_SYSTEM_CONFIG"] =
        File.join(fixtures_base, "sys_config_w_term_manager.yml")
    end
    after do
      ENV.delete("COLLECTIONSPACE_MIGRATION_TOOLS_SYSTEM_CONFIG")
    end

    let(:config_hash) do
      h = valid_config_hash[:client]
      h.delete(:mapper_dir)
      h
    end

    context "when untangler lacks release prefix" do
      let(:sysconfig) do
        path = ENV["COLLECTIONSPACE_MIGRATION_TOOLS_SYSTEM_CONFIG"]
        h = CMT::Parse::YamlConfig.call(path).value!
        h[:cs_app_version] = "8_1_1"
        CMT::Config::System.call(hash: h).value!
      end

      it "returns Success" do
        expect(result).to be_a(Dry::Monads::Success)
        expect(result.value!.mapper_dir).to eq(
          File.join(fixtures_base, "untangler", "data", "mappers",
            "community_profiles", "8_1_1", "anthro")
        )
      end
    end

    context "when untangler has release prefix" do
      let(:sysconfig) do
        path = ENV["COLLECTIONSPACE_MIGRATION_TOOLS_SYSTEM_CONFIG"]
        h = CMT::Parse::YamlConfig.call(path).value!
        h[:cs_app_version] = "8_2"
        CMT::Config::System.call(hash: h).value!
      end

      it "returns Success" do
        expect(result).to be_a(Dry::Monads::Success)
        expect(result.value!.mapper_dir).to eq(
          File.join(fixtures_base, "untangler", "data", "mappers",
            "community_profiles", "release_8_2", "anthro")
        )
      end
    end

    context "when mapper_dir cannot be found" do
      let(:sysconfig) do
        path = ENV["COLLECTIONSPACE_MIGRATION_TOOLS_SYSTEM_CONFIG"]
        h = CMT::Parse::YamlConfig.call(path).value!
        h[:cs_app_version] = "6_1"
        CMT::Config::System.call(hash: h).value!
      end

      it "returns Failure" do
        expect(result).to be_a(Dry::Monads::Failure)
        expect(result.failure).to match(
          /mapper_dir is missing/
        )
      end
    end

    context "when cs_app_version overridden in client config" do
      let(:config_hash) do
        h = valid_config_hash[:client]
        h.delete(:mapper_dir)
        h[:cs_app_version] = "8_1_1"
        h
      end

      let(:sysconfig) do
        path = ENV["COLLECTIONSPACE_MIGRATION_TOOLS_SYSTEM_CONFIG"]
        h = CMT::Parse::YamlConfig.call(path).value!
        h[:cs_app_version] = "8_2"
        CMT::Config::System.call(hash: h).value!
      end

      it "returns Success" do
        expect(result).to be_a(Dry::Monads::Success)
        expect(result.value!.mapper_dir).to eq(
          File.join(fixtures_base, "untangler", "data", "mappers",
            "community_profiles", "8_1_1", "anthro")
        )
      end
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
