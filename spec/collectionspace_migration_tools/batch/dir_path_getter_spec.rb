# frozen_string_literal: true

require 'fileutils'
require_relative '../../spec_helper'

RSpec.describe CollectionspaceMigrationTools::Batch::DirPathGetter do
  before do
    allow(Time).to receive(:now).and_return(Time.new(2022, 3, 7, 17, 22, 33))
    CMT.config.client.batch_dir = File.join(Bundler.root, 'tmp')
  end

  let(:timestamp){ '2022-03-07_17_22' }
  let(:mapper){ CMT::RecordMapper.new(mapper_hash)}
  
  describe '#call' do
    context 'without batch' do
      let(:path){ File.join(CMT.config.client.batch_dir, "#{timestamp}_#{rectype_segment}") }
      let(:result){ described_class.call(mapper) }

      context 'with authority' do
        let(:rectype_segment){ 'person_ulan_pa' }
        let(:mapper_hash) do
          {
            'config' => {
              'recordtype' => 'person',
              'service_type' => 'authority',
              'authority_type' => 'personauthorities',
              'authority_subtype' => 'ulan_pa'
            }
          }
        end

        it 'returns Success containing expected path', :aggregate_failures do
          expect(result).to be_a(Dry::Monads::Success)
          expect(result.value!).to eq(path)
          expect(Dir.exist?(path)).to be true
          FileUtils.rm_rf(path)
          expect(Dir.exist?(path)).to be false
        end
      end

      context 'with collectionobject' do
        let(:rectype_segment){ 'collectionobject' }
        let(:mapper_hash) do
          {
            'config' => {
              'recordtype' => 'collectionobject',
              'service_type' => 'object',
              'service_path' => 'collectionobjects'
            }
          }
        end

        it 'returns Success containing expected path', :aggregate_failures do
          expect(result).to be_a(Dry::Monads::Success)
          expect(result.value!).to eq(path)
          expect(Dir.exist?(path)).to be true
          FileUtils.rm_rf(path)
          expect(Dir.exist?(path)).to be false
        end
      end
    end

    context 'with batch' do
      let(:batch){ 'co1' }
      let(:mapper_hash) do
        {
          'config' => {
            'recordtype' => 'person',
            'service_type' => 'authority',
            'authority_type' => 'personauthorities',
            'authority_subtype' => 'ulan_pa'
          }
        }
      end
      let(:path){ File.join(CMT.config.client.batch_dir, "#{batch}_#{timestamp}") }
      let(:result){ described_class.call(mapper, batch) }

      it 'returns Success containing expected path', :aggregate_failures do
        expect(result).to be_a(Dry::Monads::Success)
        expect(result.value!).to eq(path)
        expect(Dir.exist?(path)).to be true
        FileUtils.rm_rf(path)
        expect(Dir.exist?(path)).to be false
      end
    end
    
  end
end
