# frozen_string_literal: true

require_relative '../spec_helper'

RSpec.describe CollectionspaceMigrationTools::Configuration do
  let(:result){ described_class.new(client: config_file) }

  context 'with valid config' do
    let(:config_file){ valid_config_path }

    it 'returns Configuration object', :aggregate_failures do
      expect(result).to be_a(CMT::Configuration)
      expect(result.client.base_uri).to eq('https://core.dev.collectionspace.org/cspace-services')
      expect(result.database.db_name).to eq('cs_cs')
    end
  end

  context 'with invalid config' do
    let(:config_file){ invalid_config_path }

    # If this test fails make sure you do not have redis running
    it 'outputs error message and exits' do
      expect{ result }
        .to output(/Could not create config/).to_stdout.and raise_error(SystemExit)
    end
  end
end
