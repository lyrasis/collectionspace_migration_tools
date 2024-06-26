# frozen_string_literal: true

require_relative "../../spec_helper"

RSpec.describe CollectionspaceMigrationTools::Parse::BatchConfig do
  let(:base_config) do
    {"status_check_method" => "cache", "search_if_not_cached" => false}
  end

  describe "#call" do
    let(:result) { described_class.call }

    context "when no batch config file indicated in client config" do
      before { CMT.config.client.batch_config_path = nil }

      it "is Success containing expected hash" do
        expect(result).to be_a(Dry::Monads::Success)
        expect(result.value!).to eq(base_config)
      end
    end

    context "when batch config file indicated in client config" do
      before do
        path = File.join(Bundler.root, "spec", "support", "fixtures",
          "client_batch_config.json")
        CMT.config.client.batch_config_path = path
      end

      it "is Success containing expected hash" do
        expected = base_config.merge({"delimiter" => "|||",
"subgroup_delimiter" => "^^"})
        expect(result).to be_a(Dry::Monads::Success)
        expect(result.value!).to eq(expected)
      end
    end

    context "when bad batch config path indicated in client config" do
      before do
        path = File.join(Bundler.root, "spec", "support", "fixtures",
          "missing_batch_config.json")
        CMT.config.client.batch_config_path = path
      end
      after { CMT.config.client.batch_config_path = nil }

      it "is Failure" do
        expect(result).to be_a(Dry::Monads::Failure)
        expect(result.failure.message).to start_with("Batch config file does not exist")
      end
    end
  end
end
