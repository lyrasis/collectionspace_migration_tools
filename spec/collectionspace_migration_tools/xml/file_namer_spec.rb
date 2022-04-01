# frozen_string_literal: true

require_relative '../../spec_helper'

# These tests assume the correct action has been assigned by `CMT::XML::ServicesApiActionChecker`
#   That is, we don't check here for weird edge cases where the response for a DELETE does not
#   contain a CSID, etc.

RSpec.describe CollectionspaceMigrationTools::Xml::FileNamer do
  let(:klass){ described_class.new }
  let(:response){ double('Response', identifier: rec_id) }
  let(:hashed){ "#{Base64.urlsafe_encode64(rec_id)}.xml" }
    
  describe '#call' do
    let(:result){ klass.call(response) }

    context 'with rec_id = 123' do
      let(:rec_id){ '123' }
      it 'returns Success containing expected name', :aggregate_failures do
        expect(result).to be_a(Dry::Monads::Success)
        expect(result.value!).to eq(hashed)
      end
    end

    context 'with rec_id = ' do
      let(:rec_id){ '' }
      it 'returns Failure', :aggregate_failures do
        expect(result).to be_a(Dry::Monads::Failure)
        expect(result.failure.message).to eq('no id found for record')
      end
    end
  end
end
