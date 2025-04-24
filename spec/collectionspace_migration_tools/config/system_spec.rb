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
    end
  end

  context "when bastion_user given" do
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

  context "when missing system aws_profile" do
    let(:config) do
      data = sys_config_hash.dup
      data.delete(:aws_profile)
      data
    end

    it "returns Failure with expected message" do
      expect(result).to be_a(Dry::Monads::Failure)
      expect(result.failure).to match(/aws_profile is missing$/)
    end
  end

  context "when term_manager_config_dir is not found" do
    let(:config) do
      data = sys_config_hash.dup
      data[:term_manager_config_dir] = "thisappdir/terms"
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
