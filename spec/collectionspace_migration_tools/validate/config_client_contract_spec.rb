# frozen_string_literal: true

require_relative '../../spec_helper'

RSpec.describe CollectionspaceMigrationTools::Validate::ConfigClientContract do
  let(:valid_config){ valid_config_hash[:client] }
  let(:result){ described_class.new.call(client_config).to_monad }

  context 'with valid data' do
    let(:client_config){ valid_config }

    it 'returns Success' do
      expect(result).to be_a(Dry::Monads::Success)
    end
  end

  context 'with non-services base_uri' do
    let(:client_config){ valid_config.merge({base_uri: 'something/cspace'}) }

    it 'returns Failure' do
      expect(result).to be_a(Dry::Monads::Failure)
    end
  end
end
