# frozen_string_literal: true

require_relative "../../spec_helper"

RSpec.describe CollectionspaceMigrationTools::Csv::Chunker do
  let(:csv_path) do
    File.join(Bundler.root.to_s, "spec", "support", "fixtures", "csv", csv_name)
  end

  describe ".call" do
    let(:result) { described_class.call(csv_path, chunk_size: 1) }

    context "with non-existent file" do
      let(:csv_name) { "foo.csv" }

      it "is Failure" do
        expect(result).to be_a(Dry::Monads::Failure)
        expect(result.failure).to start_with("No such file")
      end
    end

    context "with quoted headers and single column" do
      let(:csv_name) { "single_column_quoted_headers.csv" }

      it "is Success" do
        expect(result).to be_a(Dry::Monads::Success)
        v = result.value!
        expect(v).to be_a(SmarterCSV::Reader)
        v.process
        expect(v.chunk_count).to eq(3)
      end
    end

    context "with newline and quotes in quoted cell" do
      let(:csv_name) { "line_feed_in_quoted_val.csv" }

      it "is Success" do
        expect(result).to be_a(Dry::Monads::Success)
        v = result.value!
        expect(v).to be_a(SmarterCSV::Reader)
        v.process
        expect(v.chunk_count).to eq(3)
      end
    end
  end
end
