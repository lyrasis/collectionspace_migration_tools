# frozen_string_literal: true

require_relative '../../spec_helper'

RSpec.describe CollectionspaceMigrationTools::Batch::CachingPlanner do
  let(:klass){ described_class.new(refname: rndep, csid: csiddep) }

  describe '#call' do
    let(:result){ klass.call }

    context 'with overlapping dependencies' do
      let(:csiddep){ 'a|b|c|f' }
      let(:rndep){ 'b|c|d|e' }
      let(:expected) do
            {
              populate_both_caches: %w[b c],
              populate_csid_cache: %w[a f],
              populate_refname_cache: %w[d e]
            }
          end
          
      it 'returns expected', :aggregate_failures do
        expect(result).to be_a(Dry::Monads::Success)
        expect(result.value!).to eq(expected)
      end
    end

    context 'with non-overlapping dependencies' do
      let(:csiddep){ 'a|b|c' }
      let(:rndep){ 'd|e|f' }
      let(:expected) do
        {
          populate_csid_cache: %w[a b c],
          populate_refname_cache: %w[d e f]
        }
      end
      
      it 'returns expected', :aggregate_failures do
        expect(result).to be_a(Dry::Monads::Success)
        expect(result.value!).to eq(expected)
      end
    end

    context 'with no dependencies' do
      let(:csiddep){ '' }
      let(:rndep){ '' }
      let(:expected){ {} }
      
      it 'returns expected', :aggregate_failures do
        expect(result).to be_a(Dry::Monads::Success)
        expect(result.value!).to eq(expected)
      end
    end
  end
end
