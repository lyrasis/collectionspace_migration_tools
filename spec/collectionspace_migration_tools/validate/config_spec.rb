# frozen_string_literal: true

require_relative '../../spec_helper'

RSpec.describe CollectionspaceMigrationTools::Validate::Config do
  subject(:validator){ described_class }

  describe '.call' do
    let(:result){ validator.call(config_data) }

    context 'with valid data' do
      let(:config_data){ valid_config_hash.dup }

      it 'returns Success containing Hash', :aggregate_failures do
        expect(result.success?).to be true
        expect(result.value!).to be_a(Hash)
      end
    end

    context 'with invalid client config' do
      let(:config_data) do
        data = valid_config_hash.dup
        data[:client][:base_uri] = 'something/cspace'
        data
      end

      it 'returns Failure with expected message', :aggregate_failures do
        expect(result).to be_a(Dry::Monads::Failure)
        expect(result.failure.message).to eq('base_uri must end with "/cspace-services"')
      end
    end

    context 'with old, bucket-specific settings in client config' do
      let(:config_data) do
        data = valid_config_hash.dup
        data[:client][:s3_region] = 'us-west-2'
        data[:client][:s3_key] = 'key'
        data[:client][:s3_secret] = 'secret'
        data
      end

      it 'returns Success and warns to STDOUT', :aggregate_failures do
        msg = validator.send(:deprecated_client_setting_msg)
        expect(validator).to receive(:warn).with(msg)
        expect(result).to be_a(Dry::Monads::Success)
      end
    end

    context 'with invalid db config' do
      let(:config_data) do
        data = valid_config_hash.dup
        data[:database][:db_host] = 'target-db-bastion.collectionspace.org'
        data
      end

      it 'returns Failure with expected message', :aggregate_failures do
        expect(result).to be_a(Dry::Monads::Failure)
        expect(result.failure.message).to eq('db_host must not contain "-bastion"')
      end
    end

    context 'with invalid client and db config' do
      let(:config_data) do
        data = valid_config_hash.dup
        data[:client][:base_uri] = 'something/cspace'
        data[:database][:db_host] = 'target-db-bastion.collectionspace.org'
        data
      end

      it 'returns Failure with expected message', :aggregate_failures do
        expect(result).to be_a(Dry::Monads::Failure)
        msg = 'base_uri must end with "/cspace-services"; db_host must not contain "-bastion"'
        expect(result.failure.message).to eq(msg)
      end
    end

    context 'when missing system aws_profile' do
      let(:config_data) do
        data = valid_config_hash.dup
          .merge(sys_config_hash)
        data[:system].delete(:aws_profile)
        data
      end

      it 'returns Failure with expected message', :aggregate_failures do
        expect(result).to be_a(Dry::Monads::Failure)
        expect(result.failure.message).to eq('aws_profile is missing')
      end
    end
  end
end
