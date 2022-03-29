# frozen_string_literal: true

require_relative '../../spec_helper'

RSpec.describe CollectionspaceMigrationTools::Xml::ServicesApiActionChecker do
  let(:klass){ described_class.new(action) }
  
  describe '#call' do
    let(:result){ klass.call(response) }
    let(:response_new) do
      response = CollectionSpace::Mapper::Response.new({'objectnumber' => '123'})
      response.merge_status_data({status: :new})
      response
    end
    let(:response_existing) do
      response = CollectionSpace::Mapper::Response.new({'objectnumber' => '123'})
      response.merge_status_data({status: :existing})
      response
    end
    
    context 'with given action = create' do
      let(:action){ 'CREATE' }
      
      context 'when rec status = new' do
        let(:response){ response_new }
        it 'returns CREATE', :aggregate_failures do
          expect(result).to be_a(Dry::Monads::Success)
          expect(result.value!).to eq('CREATE')
          expect(response.warnings.size).to eq(0)
        end
      end

      context 'when rec status = existing' do
        let(:response){ response_existing }
        it 'returns UPDATE', :aggregate_failures do
          expect(result).to be_a(Dry::Monads::Success)
          expect(result.value!).to eq('UPDATE')
          expect(response.warnings.size).to eq(1)
        end
      end
    end

    context 'with given action = update' do
      let(:action){ 'UPDATE' }
      
      context 'when rec status = new' do
        let(:response){ response_new }
        it 'returns CREATE', :aggregate_failures do
          expect(result).to be_a(Dry::Monads::Success)
          expect(result.value!).to eq('CREATE')
          expect(response.warnings.size).to eq(1)
        end
      end

      context 'when rec status = existing' do
        let(:response){ response_existing }
        it 'returns UPDATE', :aggregate_failures do
          expect(result).to be_a(Dry::Monads::Success)
          expect(result.value!).to eq('UPDATE')
          expect(response.warnings.size).to eq(0)
        end
      end
    end

    context 'with given action = delete' do
      let(:action){ 'DELETE' }
      
      context 'when rec status = new' do
        let(:response){ response_new }
        it 'returns Failure', :aggregate_failures do
          expect(result).to be_a(Dry::Monads::Failure)
        end
      end

      context 'when rec status = existing' do
        let(:response){ response_existing }
        it 'returns DELETE', :aggregate_failures do
          expect(result).to be_a(Dry::Monads::Success)
          expect(result.value!).to eq('DELETE')
          expect(response.warnings.size).to eq(0)
        end
      end
    end

  end
end
