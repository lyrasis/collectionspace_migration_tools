# frozen_string_literal: true

require_relative "../../spec_helper"

RSpec.describe CollectionspaceMigrationTools::Validate::ConfigClientContract do
  let(:valid_config) { valid_config_hash }
  let(:result) { CMT::Config::Client.call(hash: client_config) }
  # let(:result) { described_class.new.call(client_config).to_monad }

  context "with valid data" do
    let(:client_config) { valid_config }

    it "returns Success" do
      expect(result).to be_a(Dry::Monads::Success)
    end
  end

  context "with non-services base_uri" do
    let(:client_config) do
      valid_config.dup.merge({base_uri: "something/cspace"})
    end

    it "returns Failure" do
      expect(result).to be_a(Dry::Monads::Failure)
    end
  end

  context "with bad profile" do
    let(:client_config) { valid_config.dup.merge({profile: "fineart"}) }

    it "returns Failure" do
      expect(result).to be_a(Dry::Monads::Failure)
    end
  end

  context "with bad profile version" do
    let(:client_config) { valid_config.dup.merge({profile_version: "7.0.0"}) }

    it "returns Failure" do
      expect(result).to be_a(Dry::Monads::Failure)
    end
  end

  context "with bad base_dir" do
    let(:client_config) do
      valid_config.dup.merge({base_dir: "~/non-existent_directory"})
    end

    it "returns Failure" do
      expect(result).to be_a(Dry::Monads::Failure)
    end
  end

  context "with no S3 bucket" do
    let(:client_config) do
      vc = valid_config.dup
      vc.delete(:fast_import_bucket)
      vc
    end

    it "returns Success" do
      expect(result).to be_a(Dry::Monads::Success)
    end
  end

  context "with existing batch config file" do
    let(:client_config) do
      valid_config.dup.merge({
        batch_config_path: File.join(fixtures_base, "client_batch_config.json")
      })
    end

    it "returns Success" do
      expect(result).to be_a(Dry::Monads::Success)
    end
  end

  context "with non-existent batch config file" do
    let(:client_config) do
      valid_config.dup.merge(
        {batch_config_path: File.join(fixtures_base, "batch_config.json")}
      )
    end

    it "returns Failure" do
      expect(result).to be_a(Dry::Monads::Failure)
    end
  end
end
