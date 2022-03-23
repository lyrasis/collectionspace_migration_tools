# frozen_string_literal: true

require 'fileutils'
require_relative '../spec_helper'

RSpec.describe CollectionspaceMigrationTools::RecordMapper do
  let(:mapper){ described_class.new(hash) }
  
  context 'with authority' do
    let(:hash) do
      {
        'config' => {
          'recordtype' => 'person',
          'service_type' => 'authority',
          'authority_type' => 'personauthorities',
          'authority_subtype' => 'ulan_pa',
          'service_path' => 'personauthorities'
        }
      }
    end

    describe '#authority?' do
      it 'returns true' do
        expect(mapper.authority?).to be true
      end
    end

    describe '#type' do
      it 'returns personauthorities' do
        expect(mapper.type).to eq('personauthorities')
      end
    end

    describe '#type_subtype' do
      it 'returns person_ulan_pa' do
        expect(mapper.type_subtype).to eq('person_ulan_pa')
      end
    end

    describe '#type_label' do
      it 'returns person' do
        expect(mapper.type_label).to eq('person')
      end
    end

    describe '#subtype' do
      it 'returns ulan_pa' do
        expect(mapper.subtype).to eq('ulan_pa')
      end
    end

    describe '#service_path' do
      it 'returns personauthorities' do
        expect(mapper.service_path).to eq('personauthorities')
      end
    end
  end

  context 'with collectionobject' do
    let(:hash) do
      {
        'config' => {
          'recordtype' => 'collectionobject',
          'service_type' => 'object',
          'service_path' => 'collectionobjects'
        }
      }
    end

    describe '#authority?' do
      it 'returns false' do
        expect(mapper.authority?).to be false
      end
    end

    describe '#type' do
      it 'returns collectionobjects' do
        expect(mapper.type).to eq('collectionobjects')
      end
    end

    describe '#type_subtype' do
      it 'returns collectionobject' do
        expect(mapper.type_subtype).to eq('collectionobject')
      end
    end

    describe '#type_label' do
      it 'returns collectionobject' do
        expect(mapper.type_label).to eq('collectionobject')
      end
    end

    describe '#subtype' do
      it 'returns nil' do
        expect(mapper.subtype).to be_nil
      end
    end

    describe '#service_path' do
      it 'returns collectionobjects' do
        expect(mapper.service_path).to eq('collectionobjects')
      end
    end
  end
end

