# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CollectionspaceMigrationTools::Configuration do
  let(:config_path) { File.join(Bundler.root, 'spec', 'support', 'fixtures', config_file) } 
  let(:result) { described_class.new(config_path) }

  context 'with valid config' do
    let(:config_file) { 'config_valid.yml' }

    it 'returns Configuration object' do
      expect(result).to be_a(CMT::Configuration)
      expect(result.client.base_uri).to eq('https://core.dev.collectionspace.org/cspace-services')
      expect(result.database.db_name).to eq('db_db')
    end
  end

  context 'with invalid config' do
    let(:config_file) { 'config_invalid.yml' }
    it 'outputs error message' do
      expect{result}.to output(/Could not create config.*Exiting/).to_stdout
    end

    it 'exits application' do
      expect{result}.to raise_error(SystemExit)
    end
  end
end

