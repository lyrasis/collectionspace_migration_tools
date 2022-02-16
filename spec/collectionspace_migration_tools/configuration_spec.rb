# frozen_string_literal: true

require_relative '../spec_helper'

RSpec.describe CollectionspaceMigrationTools::Configuration do
  let(:result){ described_class.new(client: config_file) }

  context 'with valid config' do
    let(:config_file){ valid_config_path }

    it 'returns Configuration object', :aggregate_failures do
      expect(result).to be_a(CMT::Configuration)
      expect(result.client.base_uri).to eq('https://core.dev.collectionspace.org/cspace-services')
      expect(result.database.db_name).to eq('db_db')
    end
  end

  context 'with invalid config' do
    let(:config_file){ invalid_config_path }

    it 'outputs error message and exits' do
      out = <<~OUT
        Could not create config.
        Error occurred in: CollectionspaceMigrationTools::Validate::Config
        Error message: base_uri must end with "/cspace-services"; db_host must not contain "-bastion"; bastion_host must contain "-bastion"
        Exiting...
      OUT
      expect{ result }
        .to output(out).to_stdout.and raise_error(SystemExit)
    end
  end
end
