# frozen_string_literal: true

require_relative '../../spec_helper'

RSpec.describe CollectionspaceMigrationTools::Xml::ServicesApiPathGetter do
  
  describe '#call' do
    let(:mapper){ CMT::RecordMapper.new(mapper_hash)}
    let(:result){ described_class.call(mapper) }

    context 'with authority' do
      let(:mapper_hash) do
        {
          'config' => {
            'service_type' => 'authority',
            'authority_type' => 'personauthorities',
            'authority_subtype' => 'ulan_pa'
          }
        }
      end

      it 'returns Success containing expected path', :aggregate_failures do
        path = '/personauthorities/urn:cspace:name(ulan_pa)/items'
        expect(result).to be_a(Dry::Monads::Success)
        expect(result.value!).to eq(path)
      end
    end

    context 'with collectionobject' do
      let(:mapper_hash) do
        {
          'config' => {
            'service_type' => 'object',
            'service_path' => 'collectionobjects'
          }
        }
      end

      it 'returns Success containing expected path', :aggregate_failures do
        path = '/collectionobjects'
        expect(result).to be_a(Dry::Monads::Success)
        expect(result.value!).to eq(path)
      end
    end
  end
end
