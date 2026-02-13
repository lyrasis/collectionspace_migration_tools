# frozen_string_literal: true

require_relative "../../spec_helper"

RSpec.describe CollectionspaceMigrationTools::Config::System do
  let(:result) do
    described_class.call(hash: config)
  end

  context "when valid config" do
    let(:config) { sys_config_hash.dup }

    it "returns Success" do
      expect(result).to be_a(Dry::Monads::Success)
      expect(result.value!.db_tunnel_connection_pause).to eq(3)
    end
  end

  context "when bastion_user overridden" do
    let(:config) do
      data = sys_config_hash.dup
      data[:bastion_user] = "name"
      data
    end

    it "returns Success" do
      expect(result).to be_a(Dry::Monads::Success)
      expect(result.value!.bastion_user).to eq("name")
    end
  end

  context "when db_tunnel_connection_pause overridden" do
    let(:config) do
      data = sys_config_hash.dup
      data[:db_tunnel_connection_pause] = 6
      data
    end

    it "returns Success" do
      expect(result).to be_a(Dry::Monads::Success)
      expect(result.value!.db_tunnel_connection_pause).to eq(6)
    end
  end

  context "when missing system client_config_dir setting" do
    let(:config) do
      data = sys_config_hash.dup
      data.delete(:client_config_dir)
      data
    end

    it "returns Failure with expected message" do
      expect(result).to be_a(Dry::Monads::Failure)
      expect(result.failure).to match(/client_config_dir is missing$/)
    end
  end

  context "when missing system cspace_config_untangler_dir setting" do
    let(:config) do
      data = sys_config_hash.dup
      data.delete(:cspace_config_untangler_dir)
      data
    end

    it "returns Failure with expected message" do
      expect(result).to be_a(Dry::Monads::Failure)
      expect(result.failure).to match(/cspace_config_untangler_dir is missing$/)
    end
  end

  context "when cspace_config_untangler_dir given but dir doesn't exist" do
    let(:config) do
      data = sys_config_hash.dup
      data[:cspace_config_untangler_dir] = "fixturesdir/nope"
      data
    end

    it "returns Failure with expected message" do
      expect(result).to be_a(Dry::Monads::Failure)
      expect(result.failure).to match(
        /cspace_config_untangler_dir .*nope does not exist/
      )
    end
  end

  context "when term_manager_config_dir given but dir doesn't exist" do
    let(:config) do
      data = sys_config_hash.dup
      data[:term_manager_config_dir] = "fixturesdir/terms"
      data
    end

    it "returns Failure with expected message" do
      expect(result).to be_a(Dry::Monads::Failure)
      expect(result.failure).to match(
        /term_manager_config_dir .*terms does not exist/
      )
    end
  end

  context "when cs_app_version overridden in yaml" do
    let(:config) do
      path = File.join(fixtures_base, "sys_config_w_term_manager.yml")
      CMT::Parse::YamlConfig.call(path).value!
    end

    it "comes through as a valid string" do
      expect(result).to be_a(Dry::Monads::Success)
      expect(result.value!.cs_app_version).to eq("8_1_1")
    end
  end

  context "with bad cs_app_version format" do
    let(:config) do
      data = sys_config_hash.dup
      data[:cs_app_version] = "8.2"
      data
    end

    it "returns Failure" do
      expect(result).to be_a(Dry::Monads::Failure)
      expect(result.failure).to match(
        /cs_app_version must follow pattern/
      )
    end
  end
end
