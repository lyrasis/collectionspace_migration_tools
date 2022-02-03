# frozen_string_literal: true

require_relative '../../spec_helper'

RSpec.describe CollectionspaceMigrationTools::Validate::ConfigDatabaseContract do
  let(:valid_config) do
    {
      db_password: 'password',
      db_name: 'db_db',
      db_host: 'target-db.collectionspace.org',
      bastion_user: 'me',
      bastion_host: 'target-db-bastion.collectionspace.org'
    }
  end
  let(:result){ described_class.new.call(client_config).to_monad }

  context 'with valid data' do
    let(:client_config){ valid_config }

    it 'returns Success' do
      expect(result).to be_a(Dry::Monads::Success)
    end
  end

  context 'with hosts swapped' do
    let(:client_config) do
      valid_config.merge({
        db_host: 'target-db-bastion.collectionspace.org',
        bastion_host: 'target-db.collectionspace.org'
      })
    end

    it 'returns Failure' do
      expect(result).to be_a(Dry::Monads::Failure)
    end
  end
end
