# frozen_string_literal: true

require_relative "../../spec_helper"

RSpec.describe CollectionspaceMigrationTools::Validate::ConfigClientContract do
  let(:valid_config) { valid_config_hash[:client] }
  let(:result) { described_class.new.call(client_config).to_monad }

  context "with valid data" do
    let(:client_config) { valid_config }

    it "returns Success" do
      expect(result).to be_a(Dry::Monads::Success)
    end
  end

  context "with non-services base_uri" do
    let(:client_config) { valid_config.merge({base_uri: "something/cspace"}) }

    it "returns Failure" do
      expect(result).to be_a(Dry::Monads::Failure)
    end
  end

  context "with bad cs_version" do
    let(:client_config) { valid_config.merge({cs_version: "7.0"}) }

    it "returns Failure" do
      expect(result).to be_a(Dry::Monads::Failure)
    end
  end

  context "with bad profile" do
    let(:client_config) { valid_config.merge({profile: "fineart"}) }

    it "returns Failure" do
      expect(result).to be_a(Dry::Monads::Failure)
    end
  end

  context "with bad profile version" do
    let(:client_config) { valid_config.merge({profile_version: "7.0.0"}) }

    it "returns Failure" do
      expect(result).to be_a(Dry::Monads::Failure)
    end
  end

  context "with bad base_dir" do
    let(:client_config) do
      valid_config.merge({base_dir: "~/non-existent_directory"})
    end

    it "returns Failure" do
      expect(result).to be_a(Dry::Monads::Failure)
    end
  end

  context "with existing batch config file" do
    let(:client_config) do
      valid_config.merge({batch_config_path: "~/code/cs/migration_tools/spec/support/fixtures/client_batch_config.json"})
    end

    it "returns Success" do
      expect(result).to be_a(Dry::Monads::Success)
    end
  end

  context "with non-existent batch config file" do
    let(:client_config) do
      valid_config.merge({batch_config_path: "~/code/cs/migration_tools/spec/support/fixtures/batch_config.json"})
    end

    it "returns Failure" do
      expect(result).to be_a(Dry::Monads::Failure)
    end
  end
end
