# frozen_string_literal: true

require_relative "../spec_helper"

RSpec.describe CollectionspaceMigrationTools::Configuration do
  let(:result) { described_class.new(client: config_file) }

  context "with valid config without optional settings" do
    let(:config_file) { valid_config_path }

    it "returns Configuration object", :aggregate_failures do
      expect(result).to be_a(CMT::Configuration)
      expect(result.client.base_uri).to eq("https://core.dev.collectionspace.org/cspace-services")
      expect(result.client.batch_config_path).to be_nil
      expect(result.client.batch_csv).to eq(File.join(result.client.base_dir,
        "batches.csv"))
      expect(result.database.db_name).to eq("cs_cs")
      expect(result.client.auto_refresh_cache_before_mapping).to be true
      expect(result.client.clear_cache_before_refresh).to be true
      expect(result.client.media_with_blob_upload_delay).to eq(0.25)
    end
  end

  context "with valid config with optional settings" do
    let(:config_file) do
      File.join(Bundler.root, "spec", "support", "fixtures",
        "config_valid_with_optional.yml")
    end

    it "returns Configuration object", :aggregate_failures do
      batch_cfg = File.expand_path("~/code/cs/migration_tools/spec/support/fixtures/client_batch_config.json")
      expect(result.client.batch_config_path).to eq(batch_cfg)
      expect(result.client.batch_csv).to eq(File.join(result.client.base_dir,
        "batch_tracker.csv"))
      expect(result.client.auto_refresh_cache_before_mapping).to be false
      expect(result.client.clear_cache_before_refresh).to be false
      expect(result.client.media_with_blob_upload_delay).to eq(0.5)
    end
  end

  context "with invalid config" do
    let(:config_file) { invalid_config_path }

    # If this test fails make sure you do not have redis running
    it "outputs error message and exits" do
      expect { result }
        .to output(/Could not create config/).to_stdout.and raise_error(SystemExit)
    end
  end
end
