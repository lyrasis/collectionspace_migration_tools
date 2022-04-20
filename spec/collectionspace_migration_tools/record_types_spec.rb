# frozen_string_literal: true

require_relative '../spec_helper'

RSpec.describe CollectionspaceMigrationTools::RecordTypes do
  let(:klass){ described_class }
  
  describe '#alt_auth_rectype_form' do
    let(:result){ klass.alt_auth_rectype_form(rectype) }

    context 'with subtype needing remapping' do
      let(:rectype){ 'concept-ethculture' }
      it 'returns expected', :aggregate_failures do
        expect(result).to be_a(Dry::Monads::Success)
        expect(result.value!).to eq('concept-ethnographic-culture')
      end
    end

    context 'with both parts needing remapping' do
      let(:rectype){ 'orgauthorities-ulan_oa' }
      it 'returns expected', :aggregate_failures do
        expect(result).to be_a(Dry::Monads::Success)
        expect(result.value!).to eq('organization-ulan')
      end
    end

    context 'with both parts ok as-is' do
      let(:rectype){ 'person-local' }
      it 'returns expected', :aggregate_failures do
        expect(result).to be_a(Dry::Monads::Success)
        expect(result.value!).to eq(rectype)
      end
    end

    context 'with unmappable' do
      let(:rectype){ 'foo-bar' }
      it 'returns expected', :aggregate_failures do
        expect(result).to be_a(Dry::Monads::Failure)
      end
    end
  end

  describe '#to_obj' do
    let(:result){ klass.to_obj(rectype) }

    context 'with vocabulary' do
      let(:rectype){ 'vocabulary' }
      it 'returns expected' do
        expect(result).to be_a(Dry::Monads::Success)
        expect(result.value!).to be_a(CMT::Entity::Vocabulary)
        expect(result.value!.status.success?).to be true
      end
    end

    context 'with collectionobject' do
      let(:rectype){ 'collectionobject' }
      it 'returns expected' do
        expect(result).to be_a(Dry::Monads::Success)
        expect(result.value!).to be_a(CMT::Entity::Collectionobject)
        expect(result.value!.status.success?).to be true
      end
    end

    context 'with relation' do
      let(:rectype){ 'authorityhierarchy' }
      it 'returns expected' do
        expect(result).to be_a(Dry::Monads::Success)
        expect(result.value!).to be_a(CMT::Entity::Relation)
        expect(result.value!.status.success?).to be true
      end
    end

    context 'with procedure' do
      let(:rectype){ 'group' }
      it 'returns expected' do
        expect(result).to be_a(Dry::Monads::Success)
        expect(result.value!).to be_a(CMT::Entity::Procedure)
        expect(result.value!.status.success?).to be true
      end
    end

    context 'with ok as-is authority' do
      let(:rectype){ 'person-local' }
      it 'returns expected' do
        expect(result).to be_a(Dry::Monads::Success)
        expect(result.value!).to be_a(CMT::Entity::Authority)
        expect(result.value!.status.success?).to be true
      end
    end

    context 'with remappable authority' do
      let(:rectype){ 'concept-ethculture' }
      it 'returns expected' do
        expect(result).to be_a(Dry::Monads::Success)
        expect(result.value!).to be_a(CMT::Entity::Authority)
        expect(result.value!.status.success?).to be true
      end
    end

    context 'with unmappable rectype' do
      let(:rectype){ 'foo-bar' }
      it 'returns expected' do
        expect(result).to be_a(Dry::Monads::Failure)
      end
    end
  end
end
