# frozen_string_literal: true

require_relative "../../spec_helper"

RSpec.describe CollectionspaceMigrationTools::Build::DataHandler do
  before(:all) { setup_mapping }

  describe "#call" do
    let(:mapper) { CMT::Parse::RecordMapper.call("collectionobject").value! }
    let(:config) { CMT::Parse::BatchConfig.call.value! }
    let(:result) { described_class.call(mapper, config) }

    context "with supported record type" do
      let(:rectype) { "collectionobject" }

      it "returns Success with DataHandler object" do
        expect(result).to be_a(Dry::Monads::Success)
        expect(result.value!).to be_a(CollectionSpace::Mapper::DataHandler)
        expect(result.value!.mapper.batchconfig.status_check_method).to eq("cache")
      end
    end
  end
end
