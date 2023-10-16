# frozen_string_literal: true

require_relative "../../spec_helper"

RSpec.describe CollectionspaceMigrationTools::Validate::ConfigDatabaseContract do
  let(:result) { described_class.new.call(client_config).to_monad }

  context "with valid data" do
    let(:client_config) { valid_config_hash[:database].dup }

    it "returns Success" do
      expect(result).to be_a(Dry::Monads::Success)
    end
  end

  context "with hosts swapped" do
    let(:client_config) do
      config = valid_config_hash[:database].dup
      config[:db_host] = "target-db-bastion.collectionspace.org"
      config[:bastion_host] = "target-db.collectionspace.org"
      config
    end

    it "returns Failure" do
      expect(result).to be_a(Dry::Monads::Failure)
    end
  end
end
