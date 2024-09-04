# frozen_string_literal: true

require_relative "../../spec_helper"

RSpec.describe CollectionspaceMigrationTools::Cache::Populator do
  subject(:populator) do
    described_class.new(cache_type: cache_type, rec_type: rec_type)
  end

  describe "#key_val" do
    let(:result) { populator.key_val(row) }

    context "with Procedure data" do
      let(:rec_type) { "Procedures" }
      let(:row) do
        {
          "type" => "movement",
          "id" => "123",
          "refname" => "urn:blah",
          "csid" => "a2-b2",
          "uri" => "foo"
        }
      end

      context "when csid cache" do
        let(:cache_type) { "csid" }

        it "generates as expected", skip: "flaky dependent on order" do
          expect(result).to eq(
            ["refcache::c4ec11410de7b0f96c0b2398e99a48b3a429cc1eea6676e8924b88"\
             "d0a64e90c5", "a2-b2"]
          )
        end
      end
    end
  end
end
