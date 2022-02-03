# frozen_string_literal: true

require_relative '../spec_helper'

RSpec.describe CollectionspaceMigrationTools::Validate::Config do
  let(:valid_config) do
    {
      client: {
      base_uri: 'something/cspace-services',
      username: 'valid@email.com',
      password: 'string',
      page_size: 19
    },
      database: {
        db_password: 'password',
        db_name: 'db_db',
        db_host: 'target-db.collectionspace.org',
        bastion_user: 'me',
        bastion_host: 'target-db-bastion.collectionspace.org'

      }
    }
  end
  
  let(:result) { described_class.call(config_data) }

  context 'with valid data' do
    let(:config_data) { valid_config.dup }
    it 'returns Success' do
      expect(result.success?).to be true
      expect(result.value!).to be_a(Hash)
    end
  end

  context 'with invalid client config' do
    let(:config_data) do
      data = valid_config.dup
      data[:client][:base_uri] = 'something/cspace'
      data
    end
    it 'returns Failure' do
      expect(result).to be_a(Dry::Monads::Failure)
      expect(result.failure.message).to eq('base_uri must end with "/cspace-services"')
    end
  end

  context 'with invalid db config' do
    let(:config_data) do
      data = valid_config.dup
      data[:database][:db_host] = 'target-db-bastion.collectionspace.org'
      data
    end
    it 'returns Failure' do
      expect(result).to be_a(Dry::Monads::Failure)
      expect(result.failure.message).to eq('db_host must not contain "-bastion"')
    end
  end

  context 'with invalid client and db config' do
    let(:config_data) do
      data = valid_config.dup
      data[:client][:base_uri] = 'something/cspace'
      data[:database][:db_host] = 'target-db-bastion.collectionspace.org'
      data
    end
    it 'returns Failure' do
      expect(result).to be_a(Dry::Monads::Failure)
      expect(result.failure.message).to eq('base_uri must end with "/cspace-services"; db_host must not contain "-bastion"')
    end
  end
end

