# frozen_string_literal: true

require_relative "../../../spec_helper"

RSpec.describe CollectionspaceMigrationTools::Batch::Csv::Reader do
  let(:headers) { %w[id source_csv new_col] }
  let(:klass) { described_class.new(data: data, headers: headers) }
  let(:ok_data) do
    <<~CSV
      id,source_csv,new_col
      1,csv,
      2,tsv,
    CSV
  end
  let(:duplicate_ids) do
    <<~CSV
      id,source_csv,new_col
      1,csv,
      1,tsv,
    CSV
  end
  let(:old_headers) do
    <<~CSV
      id,source_csv
      1,csv
      2,tsv
    CSV
  end
  let(:data) { ok_data }

  describe "#find_batch" do
    let(:result) { klass.find_batch(id) }
    let(:id) { "2" }

    context "when single batch found" do
      it "returns Success containing batch row", :aggregate_failures do
        expect(result).to be_a(Dry::Monads::Success)
        expect(result.value!).to be_a(CSV::Row)
      end
    end

    context "when no batch found" do
      let(:id) { "co99" }

      it "returns failure", :aggregate_failures do
        expect(result).to be_a(Dry::Monads::Failure)
        expect(result.failure).to eq("No batch with id: #{id}")
      end
    end
  end

  describe "#ids" do
    let(:result) { klass.ids }

    it "returns Array of ids" do
      expect(result).to eq(["1", "2"])
    end
  end

  describe "#rewrite" do
    let(:rewriter) { double("Rewriter") }
    let(:klass) do
      described_class.new(data: data, headers: headers, rewriter: rewriter)
    end

    it "calls rewriter as expected" do
      expect(rewriter).to receive(:call).with(klass.instance_variable_get(:@table))
      klass.rewrite
    end
  end

  describe "#to_monad" do
    let(:result) { klass.to_monad }

    context "with no duplicate ids and headers up to date" do
      it "is success", :aggregate_failures do
        expect(result).to be_a(Dry::Monads::Success)
        expect(result.value!).to be_a(described_class)
      end
    end

    context "with duplicate ids in data" do
      let(:data) { duplicate_ids }

      it "is failure", :aggregate_failures do
        expect(result).to be_a(Dry::Monads::Failure)
        msg = "Batch ids are not unique. Please manually edit and save CSV where info about batches is recorded."
        expect(result.failure).to eq(msg)
      end
    end

    context "with out of date headers" do
      let(:data) { old_headers }

      it "is failure", :aggregate_failures do
        expect(result).to be_a(Dry::Monads::Failure)
        msg = "Batch CSV headers are not up-to-date, so batch workflows may fail unexpectedly. Run `thor batches:fix_csv` to fix"
        expect(result.failure).to eq(msg)
      end
    end
  end
end
