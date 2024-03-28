# frozen_string_literal: true

require_relative "../../spec_helper"

RSpec.describe CollectionspaceMigrationTools::Csv::BatchProcessorPreparer do
  #  before{ CMT.config }

  let(:rectype) { "collectionobject" }
  let(:csv_path) do
    File.join(Bundler.root.to_s, "spec", "support", "fixtures", "csv", csv_name)
  end
  let(:action) { "create" }
  let(:csv_name) { "excel_plain_resaved_utf-8.csv" }

  describe "#call" do
    let(:result) do
      described_class.call(csv_path: csv_path, rectype: rectype, action: action)
    end

    it "is Success" do
      expect(result).to be_a(Dry::Monads::Success)
      expect(result.value!).to be_a(CMT::Csv::BatchProcessor)
    end

    context "with invalid rectype" do
    end
  end
end
