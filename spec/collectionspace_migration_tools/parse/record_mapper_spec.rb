# frozen_string_literal: true

require_relative '../../spec_helper'

RSpec.describe CollectionspaceMigrationTools::Parse::RecordMapper do
  before(:all){ setup_mapping }

  describe '#call' do
    let(:result){ described_class.call(rectype) }

    context 'when no mapper for given rectype' do
      let(:rectype){ 'movements' }

      it 'is Failure', :aggregate_failures do
        expect(result).to be_a(Dry::Monads::Failure)
        expect(result.failure.message).to start_with("No record mapper for #{rectype}")
      end
    end

    context 'with valid JSON mapper for given rectype' do
      let(:rectype){ 'objecthierarchy' }

      it 'is Success with CMT::RecordMapper' do
        expect(result).to be_a(Dry::Monads::Success)
        expect(result.value!).to be_a(CMT::RecordMapper)
      end
    end
  end
end
