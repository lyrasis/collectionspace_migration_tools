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
end
