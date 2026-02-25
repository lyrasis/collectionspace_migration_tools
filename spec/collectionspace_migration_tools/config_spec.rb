# frozen_string_literal: true

require_relative "../spec_helper"

RSpec.describe CollectionspaceMigrationTools::Config do
  describe "#current_client_config_name" do
    it "returns Failure when name file is empty",
      skip: "fix context leaks" do
      ENV["COLLECTIONSPACE_MIGRATION_TOOLS_SYSTEM_CONFIG"] =
        File.join(fixtures_base, "hosted_client_sys_config.yml")
      File.open(CMT.config.system.config_name_file, "w") do |file|
        file << ""
      end
      config = CMT::Configuration.call(mode: :check)
      result = CMT::Config.current_client_config_name(config)
      expect(result).to be_a(Dry::Monads::Failure)
      expect(result.failure.message).to match(/No client config found/)
      File.open(CMT.config.system.config_name_file, "w") do |file|
        file << "sample"
      end
      ENV.delete("COLLECTIONSPACE_MIGRATION_TOOLS_SYSTEM_CONFIG")
    end

    it "returns Success when name file contains name",
      skip: "fix context leaks" do
      ENV["COLLECTIONSPACE_MIGRATION_TOOLS_SYSTEM_CONFIG"] =
        File.join(fixtures_base, "hosted_client_sys_config.yml")
      File.open(CMT.config.system.config_name_file, "w") do |file|
        file << "sample"
      end
      config = CMT::Configuration.call(mode: :check)
      result = CMT::Config.current_client_config_name(config)
      expect(result).to be_a(Dry::Monads::Success)
      expect(result.value!).to eq("sample")
      ENV.delete("COLLECTIONSPACE_MIGRATION_TOOLS_SYSTEM_CONFIG")
    end
  end
end
