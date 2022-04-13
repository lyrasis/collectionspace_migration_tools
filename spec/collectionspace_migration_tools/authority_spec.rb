# frozen_string_literal: true

require_relative '../spec_helper'

RSpec.describe CollectionspaceMigrationTools::Authority do
  describe '.from_str' do
    let(:result){ described_class.from_str(str) }

    context 'valid rectype with slash' do
      let(:str){ 'person/local' }

      it 'constructs as expected', :aggregate_failures do
        expect(result).to be_a(described_class)
        expect(result.type).to eq('person')
        expect(result.subtype).to eq('local')
        expect(result.status.success?).to be true
      end
    end

    context 'valid rectype with hyphen' do
      let(:str){ 'person-local' }

      it 'constructs as expected', :aggregate_failures do
        expect(result).to be_a(described_class)
        expect(result.type).to eq('person')
        expect(result.subtype).to eq('local')
        expect(result.status.success?).to be true
      end
    end

    context 'invalid rectype' do
      let(:str){ 'person' }

      it 'constructs as expected', :aggregate_failures do
        expect(result).to be_a(described_class)
        expect(result.type).to eq('person')
        expect(result.subtype).to eq('')
        expect(result.status.failure?).to be true
      end
    end
  end
end
