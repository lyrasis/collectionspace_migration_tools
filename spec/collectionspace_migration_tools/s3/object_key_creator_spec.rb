# frozen_string_literal: true

require_relative '../../spec_helper'

# These tests assume the correct action has been assigned by `CMT::XML::ServicesApiActionChecker`
#   That is, we don't check here for weird edge cases where the response for a DELETE does not
#   contain a CSID, etc.

RSpec.describe CollectionspaceMigrationTools::S3::ObjectKeyCreator do
  let(:separator){ CMT.config.client.s3_delimiter }
  let(:svc_path){ '/foo' }
  let(:klass){ described_class.new(svc_path: svc_path) }
  let(:batch){ 'na' }
  let(:path){ svc_path }
  let(:rec_id){ '123' }
  let(:csid){ '456' }
  let(:hashed){ Base64.urlsafe_encode64([batch, path, rec_id, action].join(separator)) }
  
  let(:response_new) do
    response = CollectionSpace::Mapper::Response.new({'objectnumber' => rec_id})
    response.merge_status_data({status: :new})
    response.identifier = rec_id
    response
  end
  let(:response_existing) do
    response = CollectionSpace::Mapper::Response.new({'objectnumber' => rec_id})
    response.merge_status_data({status: :existing, csid: csid})
    response.identifier = rec_id
    response
  end
  
  
  describe '#call' do
    let(:result){ klass.call(response, action) }

    context 'with CREATE' do
      let(:action){ 'CREATE' }
      let(:response){ response_new }
      it 'returns Success containing expected name', :aggregate_failures do
        expect(result).to be_a(Dry::Monads::Success)
        expect(result.value!).to eq(hashed)
      end

      context 'with batch passed in' do
        let(:batch){ 'co2' }
        let(:klass){ described_class.new(svc_path: svc_path, batch: batch) }
        it 'returns Success containing expected name', :aggregate_failures do
          expect(result).to be_a(Dry::Monads::Success)
          expect(result.value!).to eq(hashed)
        end
      end
    end

    context 'with UPDATE' do
      let(:action){ 'UPDATE' }
      let(:response){ response_existing }
      let(:path) { "#{svc_path}/#{csid}" }
      it 'returns Success containing expected name', :aggregate_failures do
        expect(result).to be_a(Dry::Monads::Success)
        expect(result.value!).to eq(hashed)
      end
    end

    context 'with DELETE' do
      let(:action){ 'DELETE' }
      let(:response){ response_existing }
      let(:path) { "#{svc_path}/#{csid}" }
      it 'returns Success containing expected name', :aggregate_failures do
        expect(result).to be_a(Dry::Monads::Success)
        expect(result.value!).to eq(hashed)
      end
    end

  end
end
