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

  describe "#find_status" do
    let(:headers) do
      %w[id source_csv mappable_rectype action batch_status rec_ct
        batch_mode mapped? dir map_errs map_oks map_warns missing_terms
        uploaded? upload_errs upload_oks batch_prefix ingest_start_time
        ingest_done? ingest_complete_time ingest_duration ingest_errs
        ingest_oks duplicates_checked? duplicates]
    end
    let(:data) do
      # rubocop:disable Layout/LineLength
      <<~CSV
        id,source_csv,mappable_rectype,action,batch_status,rec_ct,batch_mode,mapped?,dir,map_errs,map_oks,map_warns,missing_terms,uploaded?,upload_errs,upload_oks,batch_prefix,ingest_start_time,ingest_done?,ingest_complete_time,ingest_duration,ingest_errs,ingest_oks,duplicates_checked?,duplicates
        plc,/path1,place-local,create,ingested,1259,full record,2024-09-11_17_25,plc_2024-09-11_17_25,0,1259,1156,0,2024-09-11_18_25,0,1259,cGxjf,2024-09-11_18_25,2024-09-11 17_35,2024-09-11 17:26:17.612,17:26:18,0,1259,2024-09-11_17_36,0
        sub,/path2,concept-associated,create,mapped,3072,full record,2024-09-11_17_38,sub_2024-09-11_17_38,0,3072,0,0,,,,,,,,,,,,
        mat,/path3,concept-material,create,uploaded,1,full record,2024-09-11_17_39,mat_2024-09-11_17_39,0,1,0,0,2024-09-11_17_42,0,1,bWF0f,2024-09-11 17:42:02.315,,,,,,,
        nom,/path4,concept-nomenclature,create,added,1000,,,,,,,,,,,,,,,,,,,
      CSV
      # rubocop:enable Layout/LineLength
    end
    let(:result) { klass.find_status(status, format).value! }

    context "when finding done, returning batches" do
      let(:status) { :done? }
      let(:format) { :batches }

      it "returns expected batches" do
        expect(result.length).to eq(1)
        expect(result.first).to be_a(CMT::Batch::Batch)
        expect(result.first.id).to eq("plc")
        expect(result.first.instance_variable_get(:@csv).table.size).to eq(4)
      end
    end

    context "when finding done, returning table" do
      let(:status) { :done? }
      let(:format) { :table }

      it "returns expected batches" do
        expect(result).to be_a(CSV::Table)
        expect(result.size).to eq(1)
      end
    end
  end

  describe "#find_batch" do
    let(:result) { klass.find_batch(id) }
    let(:id) { "2" }

    context "when single batch found" do
      it "returns Success containing batch row" do
        expect(result).to be_a(Dry::Monads::Success)
        expect(result.value!).to be_a(CSV::Row)
      end
    end

    context "when no batch found" do
      let(:id) { "co99" }

      it "returns failure" do
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
      expect(rewriter).to receive(:call)
        .with(klass.instance_variable_get(:@table))
      klass.rewrite
    end
  end

  describe "#to_monad" do
    let(:result) { klass.to_monad }

    context "with no duplicate ids and headers up to date" do
      it "is success" do
        expect(result).to be_a(Dry::Monads::Success)
        expect(result.value!).to be_a(described_class)
      end
    end

    context "with duplicate ids in data" do
      let(:data) { duplicate_ids }

      it "is failure" do
        expect(result).to be_a(Dry::Monads::Failure)
        msg = "Batch ids are not unique. Please manually edit and save CSV "\
          "where info about batches is recorded."
        expect(result.failure).to eq(msg)
      end
    end

    context "with out of date headers" do
      let(:data) { old_headers }

      it "is failure" do
        expect(result).to be_a(Dry::Monads::Failure)
        msg = "Batch CSV headers are not up-to-date, so batch workflows may "\
          "fail unexpectedly. Run `thor batches:fix_csv` to fix"
        expect(result.failure).to eq(msg)
      end
    end
  end
end
