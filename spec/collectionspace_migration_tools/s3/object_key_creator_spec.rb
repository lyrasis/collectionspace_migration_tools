# frozen_string_literal: true

require_relative "../../spec_helper"

# These tests assume the correct action has been assigned by
#   `CMT::XML::ServicesApiActionChecker`. That is, we don't check here for
#   weird edge cases where the response for a DELETE does not contain a CSID,
#   etc.

RSpec.describe CollectionspaceMigrationTools::S3::ObjectKeyCreator do
  let(:separator) { CMT.config.client.s3_delimiter }
  let(:svc_path) { "/foo" }
  let(:klass) { described_class.new(svc_path: svc_path) }
  let(:batch) { "na" }
  let(:path) { svc_path }
  let(:rec_id) { "123" }
  let(:csid) { "456" }
  let(:hashed) do
    Base64.urlsafe_encode64([batch, path, rec_id, action].join(separator))
  end

  let(:response_new) do
    response = CollectionSpace::Mapper::Response.new({"objectnumber" => rec_id})
    response.merge_status_data({status: :new})
    response.identifier = rec_id
    response
  end
  let(:response_existing) do
    response = CollectionSpace::Mapper::Response.new({"objectnumber" => rec_id})
    response.merge_status_data({status: :existing, csid: csid})
    response.identifier = rec_id
    response
  end

  describe "#call" do
    let(:result) { klass.call(response, action) }

    context "with CREATE" do
      let(:action) { "CREATE" }
      let(:response) { response_new }
      it "returns Success containing expected name", :aggregate_failures do
        expect(result).to be_a(Dry::Monads::Success)
        expect(result.value!.value).to eq(hashed)
      end

      context "with batch passed in" do
        let(:batch) { "co2" }
        let(:klass) { described_class.new(svc_path: svc_path, batch: batch) }
        it "returns Success containing expected name", :aggregate_failures do
          expect(result).to be_a(Dry::Monads::Success)
          expect(result.value!.value).to eq(hashed)
        end
      end

      context "when media with blob" do
        let(:svc_path) { "/media" }
        let(:blob_uri) { "http://place.io/img.jpg" }
        let(:response) do
          response = CollectionSpace::Mapper::Response.new(
            {"identificationnumber" => rec_id,
             "mediafileuri" => blob_uri}
          )
          response.merge_status_data({status: :new})
          response.identifier = rec_id
          response
        end
        let(:path) { "#{svc_path}?blobUri=#{blob_uri}" }
        it "returns Success containing expected name", :aggregate_failures do
          expect(result).to be_a(Dry::Monads::Success)
          expect(result.value!.value).to eq(hashed)
        end

        context "with funky mediafileuri" do
          let(:blob_uri) { "http://place.io/img (4).jpg" }
          it "returns Success containing expected name", :aggregate_failures do
            expect(result).to be_a(Dry::Monads::Success)
            res = result.value!
            expect(res.value).to eq(hashed)
            expect(res.warnings.length).to eq(1)
          end
        end
      end

      context "when media without blob" do
        let(:svc_path) { "/media" }
        let(:response) do
          response = CollectionSpace::Mapper::Response.new(
            {"identificationnumber" => rec_id}
          )
          response.merge_status_data({status: :new})
          response.identifier = rec_id
          response
        end
        it "returns Success containing expected name", :aggregate_failures do
          expect(result).to be_a(Dry::Monads::Success)
          expect(result.value!.value).to eq(hashed)
        end
      end
    end

    context "with UPDATE" do
      let(:action) { "UPDATE" }
      let(:response) { response_existing }
      let(:path) { "#{svc_path}/#{csid}" }
      it "returns Success containing expected name", :aggregate_failures do
        expect(result).to be_a(Dry::Monads::Success)
        expect(result.value!.value).to eq(hashed)
      end
    end

    context "with DELETE" do
      let(:action) { "DELETE" }
      let(:response) { response_existing }
      let(:path) { "#{svc_path}/#{csid}" }
      it "returns Success containing expected name", :aggregate_failures do
        expect(result).to be_a(Dry::Monads::Success)
        expect(result.value!.value).to eq(hashed)
      end
    end
  end
end
