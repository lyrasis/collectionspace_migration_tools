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
    double(status: :new, identifier: rec_id)
  end
  let(:response_existing) do
    double(status: :existing, csid: csid, identifier: rec_id)
  end

  describe "#call" do
    let(:result) { klass.call(response, action) }

    context "with CREATE" do
      let(:action) { "CREATE" }
      let(:response) { response_new }
      it "returns Success containing expected name" do
        expect(result.value!.value).to eq(hashed)
      end

      context "with batch passed in" do
        let(:batch) { "co2" }
        let(:klass) { described_class.new(svc_path: svc_path, batch: batch) }
        it "returns Success containing expected name" do
          expect(result.value!.value).to eq(hashed)
        end
      end

      context "when media with blob" do
        let(:svc_path) { "/media" }
        let(:blob_uri) { "http://place.io/img.jpg" }
        let(:response) do
          double(status: :new, identifier: rec_id,
            orig_data: {"mediafileuri" => blob_uri})
        end
        let(:path) { "#{svc_path}?blobUri=#{blob_uri}" }
        it "returns Success containing expected name" do
          expect(result.value!.value).to eq(
            "bmF8L21lZGlhP2Jsb2JVcmk9aHR0cCUzQSUyRiUyRnBsYWNlLmlvJTJGaW1nLmpwZ"\
              "3wxMjN8Q1JFQVRF"
          )
          expect(result).to be_a(Dry::Monads::Success)
        end

        context "with funky mediafileuri" do
          let(:blob_uri) { "http://place.io/img (4).jpg" }
          it "returns Success containing expected name" do
            res = result.value!
            expect(res.value).to eq("bmF8L21lZGlhP2Jsb2JVcmk9aHR0cCUzQSUyRiUyR"\
                                    "nBsYWNlLmlvJTJGaW1nJTI1MjAlMjg0JTI5LmpwZ"\
                                    "3wxMjN8Q1JFQVRF")
            # expect(res.warnings.length).to eq(1)
          end
        end
      end

      context "when media without blob" do
        let(:svc_path) { "/media" }
        let(:response) do
          double(status: :new, identifier: rec_id, orig_data: {})
        end
        it "returns Success containing expected name" do
          expect(result).to be_a(Dry::Monads::Success)
          expect(result.value!.value).to eq(hashed)
        end
      end
    end

    context "with UPDATE" do
      let(:action) { "UPDATE" }
      let(:response) { response_existing }
      let(:path) { "#{svc_path}/#{csid}" }
      it "returns Success containing expected name" do
        expect(result).to be_a(Dry::Monads::Success)
        expect(result.value!.value).to eq(hashed)
      end
    end

    context "with DELETE" do
      let(:action) { "DELETE" }
      let(:response) { response_existing }
      let(:path) { "#{svc_path}/#{csid}" }
      it "returns Success containing expected name" do
        expect(result).to be_a(Dry::Monads::Success)
        expect(result.value!.value).to eq(hashed)
      end
    end
  end
end
