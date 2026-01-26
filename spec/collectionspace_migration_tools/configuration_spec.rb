# frozen_string_literal: true

require_relative "../spec_helper"

RSpec.describe CollectionspaceMigrationTools::Configuration do
  let(:result) { described_class.call(client: config_file) }

  context "with valid config without optional settings" do
    let(:config_file) { valid_config_path }

    it "returns Configuration object" do
      expect(result).to be_a(CMT::Configuration)
      expect(result.client.base_uri).to eq(
        "https://core.dev.collectionspace.org/cspace-services"
      )
      expect(result.client.batch_config_path).to be_nil
      expect(result.client.batch_csv).to eq(File.join(result.client.base_dir,
        "batches.csv"))
      expect(result.client.db_name).to be_nil
      expect(result.client.auto_refresh_cache_before_mapping).to be true
      expect(result.client.clear_cache_before_refresh).to be true
      expect(result.client.media_with_blob_upload_delay).to eq(0.25)
    end
  end

  context "when redis config file is missing" do
    let(:config_file) { nil }
    before do
      ENV["COLLECTIONSPACE_MIGRATION_TOOLS_REDIS_CONFIG"] =
        File.expand_path("~/fake/redis.yml")
    end
    after do
      ENV.delete("COLLECTIONSPACE_MIGRATION_TOOLS_REDIS_CONFIG")
    end

    it "outputs error message and exits" do
      expect { result }
        .to output(/Could not create config/).to_stdout.and raise_error(
          SystemExit
        )
    end
  end

  context "with valid config with optional settings" do
    let(:config_file) do
      File.join(Bundler.root, "spec", "support", "fixtures",
        "config_valid_with_optional.yml")
    end

    it "returns Configuration object" do
      batch_cfg = File.expand_path(
        "~/code/cs/migration_tools/spec/support/fixtures/"\
          "client_batch_config.json"
      )
      expect(result.client.batch_config_path).to eq(batch_cfg)
      expect(result.client.batch_csv).to eq(File.join(result.client.base_dir,
        "batch_tracker.csv"))
      expect(result.client.auto_refresh_cache_before_mapping).to be false
      expect(result.client.clear_cache_before_refresh).to be false
      expect(result.client.media_with_blob_upload_delay).to eq(0.5)
      expect(result.client.db_host).to eq("db.domain.org")
    end
  end

  context "with invalid config" do
    let(:config_file) { invalid_config_path }

    it "outputs error message and exits" do
      expect { result }
        .to output(/Could not create config/).to_stdout.and raise_error(
          SystemExit
        )
    end
  end

  describe "#add_config" do
    let(:config_file) { valid_config_path }
    let(:config_hash) { YAML.safe_load(config_str).transform_keys!(&:to_sym) }
    let(:result) do
      config = described_class.call(client: config_file)
      config.add_config(configtype, config_hash)
    end

    context "with term_manager addition" do
      let(:configtype) { :term_manager }

      context "with valid term manager config" do
        # rubocop:disable Layout/LineLength
        let(:config_str) do
          <<~STR
            instances:
              napostaging:
            term_list_sources:
              - ~/napoproject/shared_controlled_vocabularies/dynamic_term_lists.xlsx
            authority_sources:
              ~/napoproject/shared_controlled_vocabularies/authorities_ANIMAL.xlsx: ani
              ~/napoproject/shared_controlled_vocabularies/authorities_BIRD.xlsx: brd
            version_log: ~/napoproject/shared_controlled_vocabularies/version_log.csv
          STR
        end
        # rubocop:enable Layout/LineLength

        it "adds term manager config" do
          expect(result).to be_a(Dry::Monads::Success)
          val = result.value!
          expect(val).to be_a(CMT::Configuration)
          expect(val.term_manager).to be_a(Struct)
        end
      end

      context "with valid term manager config" do
        # rubocop:disable Layout/LineLength
        let(:config_str) do
          <<~STR
            instances:
              napostaging:
            term_list_sources:
              - ~/napoproject/shared_controlled_vocabularies/dynamic_term_lists.xlsx
            authority_sources:
              ~/napoproject/shared_controlled_vocabularies/authorities_ANIMAL.xlsx: ani
              ~/napoproject/shared_controlled_vocabularies/authorities_BIRD.xlsx: brd
            version_log: ~/napoproject/shared_controlled_vocabularies/version_log.csv
            initial_term_list_load_mode: invalid
          STR
        end
        # rubocop:enable Layout/LineLength

        it "returns failure" do
          expect(result).to be_a(Dry::Monads::Failure)
          expect(result.failure).to match(
            /initial_term_list_load_mode must be one of: additive, exact/
          )
        end
      end
    end
  end
end
