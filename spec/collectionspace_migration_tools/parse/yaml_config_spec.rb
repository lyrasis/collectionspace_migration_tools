# frozen_string_literal: true

require_relative '../../spec_helper'

RSpec.describe CollectionspaceMigrationTools::Parse::YamlConfig do
  let(:config_path){ File.join(Bundler.root.to_s, 'spec', 'support', 'fixtures', config_file) }
  let(:result){ described_class.call(config_path) }

  context 'with valid file and yaml' do
    let(:config_file){ 'config_valid.yml' }

    it 'is Success' do
      expect(result).to be_a(Dry::Monads::Success)
    end
  end

  context 'with file that does not exist' do
    let(:config_file){ 'config_missing.yml' }

    it 'is Failure', :aggregate_failures do
      expect(result).to be_a(Dry::Monads::Failure)
      expect(result.failure.message).to start_with('No such file or directory')
    end
  end

  context 'with yaml file that cannot be parsed' do
    let(:config_file){ 'config_unparseable.yml' }

    it 'is Failure', :aggregate_failures do
      expect(result).to be_a(Dry::Monads::Failure)
      expect(result.failure.context).to eq('CollectionspaceMigrationTools::Parse::YamlConfig.parse')
    end
  end
end
