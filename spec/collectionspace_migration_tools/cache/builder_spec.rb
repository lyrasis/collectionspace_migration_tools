# frozen_string_literal: true

require 'mock_redis'
require_relative '../../spec_helper'

RSpec.describe CollectionspaceMigrationTools::Cache::Builder do
  before do
    redis = MockRedis.new
    allow(Redis).to receive(:new).and_return(redis)
  end
  
  let(:cache_type) { :refname }
  let(:result){ described_class.call(cache_type) }
  
  describe '.call' do
    context 'with valid config' do
      it 'returns a Success containing a CollectionSpace::RefCache object', :aggregate_failures do
        expect(result).to be_a(Dry::Monads::Success)
        expect(result.value!).to be_a(CollectionSpace::RefCache)
      end

      context 'with cache_type = :refname' do
        it 'connects to the expected Redis instance' do
          CMT.config.redis.refname_port = 9999
          CMT.config.client.redis_db_number = 9
          expected = 'redis://localhost:9999/9'
          expect(result.value!.config[:redis]).to eq(expected)
        end
      end

      context 'with cache_type = :csid' do
        let(:cache_type){ :csid }
        it 'connects to the expected Redis instance' do
          CMT.config.redis.csid_port = 9998
          CMT.config.client.redis_db_number = 9
          expected = 'redis://localhost:9998/9'
          expect(result.value!.config[:redis]).to eq(expected)
        end
      end

      context 'with unsupported cache_type' do
        let(:cache_type){ :foo }
        it 'returns a Failure with expected context and message' do
          expect(result).to be_a(Dry::Monads::Failure)
          expect(result.failure.context).to eq('CollectionspaceMigrationTools::Cache::Builder.get_port')
          msg = ':foo is not a valid cache_type value. Use :refname or :csid'
          expect(result.failure.message).to include(msg)
        end
      end
    end

    context 'with invalid config' do
      it 'returns a Failure with expected message', :aggregate_failures do
        CMT.config.client.password = '123'
        expect(result).to be_a(Dry::Monads::Failure)
        expect(result.failure.context).to eq('CollectionspaceMigrationTools::Client.verify')
        msg = 'lacks valid authentication credentials for the target'
        expect(result.failure.message).to include(msg)
      end
    end
  end
end
