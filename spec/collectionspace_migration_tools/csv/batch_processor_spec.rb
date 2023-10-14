# frozen_string_literal: true

require_relative "../../spec_helper"

RSpec.describe CollectionspaceMigrationTools::Csv::BatchProcessor do
  let(:csv_name) { "unknown_header.csv" }
  let(:csv_path) do
    File.join(Bundler.root.to_s, "spec", "support", "fixtures", "csv", csv_name)
  end
  let(:rectype) { "collectionobject" }
  let(:action) { "create" }
  let(:klass) do
    CMT::Csv::BatchProcessorPreparer.new(csv_path: csv_path, rectype: rectype,
      action: action).call.value!
  end

  describe "#call" do
    let(:result) { klass.call }
    it "returns Success" do
      expect(result).to be_a(Dry::Monads::Success)
    end
  end

  describe "#preprocess" do
    let(:result) { klass.preprocess }

    it "returns Success" do
      expect(result).to be_a(Dry::Monads::Success)
    end
  end
end
