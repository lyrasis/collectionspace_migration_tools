# frozen_string_literal: true

require_relative "../../spec_helper"

RSpec.describe CollectionspaceMigrationTools::Build::DataHandler do
  before(:all) { setup_mapping }

  describe "#call" do
    let(:mapper) { CMT::Parse::RecordMapper.call("collectionobject").value! }
    let(:config) { CMT.batch_config }
    let(:result) { described_class.call(mapper, config) }

    context "with supported record type" do
      let(:rectype) { "collectionobject" }

      it "returns Success with DataHandler object" do
        res = result.value!
        expect(res).to be_a(
          CollectionSpace::Mapper::HandlerFullRecord
        )
        status_method = res.batch.status_check_method
        expect(status_method).to eq("cache")
      end
    end
  end
end
