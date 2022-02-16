# frozen_string_literal: true

require_relative '../spec_helper'

RSpec.describe CollectionspaceMigrationTools::RefCache do
  let(:result){ described_class.call }
  
  describe '.call' do
    context 'with valid config' do
      it 'returns a Success containing a CollectionSpace::RefCache object', :aggregate_failures, skip: 'reworking class' do
        expect(result).to be_a(Dry::Monads::Success)
        expect(result.value!).to be_a(CollectionSpace::RefCache)
      end
    end

    context 'with invalid config' do
      before(:each){ CMT.config.client.password = '123' }
      after(:each){ CMT.config = Helpers.valid_config }
      it 'returns a Failure with expected message', :aggregate_failures, skip: 'reworking class' do
        expect(result).to be_a(Dry::Monads::Failure)
        expect(result.failure.context).to eq('CollectionspaceMigrationTools::Client.verify')
        msg = 'lacks valid authentication credentials for the target'
        expect(result.failure.message).to include(msg)
      end
    end
  end
end
