# frozen_string_literal: true

require_relative "../../spec_helper"

RSpec.describe CollectionspaceMigrationTools::Batch::CsvRowCounter do
  before(:all) do
    @test_csv = File.join(Bundler.root, "tmp", "test.csv")
    data = <<~CSV
      a,b,c
      d,,e
      ,f,g
      h,,i
      j,k,
      l,,m
      n,k,q
    CSV
    File.open(@test_csv, "w") { |file| file << data }
  end
  after(:all) { FileUtils.rm(@test_csv) if File.exist?(@test_csv) }

  let(:klass) { described_class.new(@test_csv) }

  describe "#call" do
    context "with no field given" do
      let(:result) { klass.call }
      it "returns Success containing total row count" do
        expect(result).to be_a(Dry::Monads::Success)
        expect(result.value!).to eq(6)
      end
    end

    context "with field given" do
      let(:result) { klass.call(field: "b") }
      it "returns Success containing count of rows where field is populated" do
        expect(result).to be_a(Dry::Monads::Success)
        expect(result.value!).to eq(3)
      end
    end

    context "with field and value given" do
      let(:result) { klass.call(field: "b", value: "k") }
      it "returns Success containing count of rows where field is populated "\
        "with given value" do
        expect(result).to be_a(Dry::Monads::Success)
        expect(result.value!).to eq(2)
      end
    end

    context "with value given without field" do
      let(:result) { klass.call(value: "k") }
      it "returns Failure" do
        expect(result).to be_a(Dry::Monads::Failure)
        expect(result.failure).to eq("CsvRowCounter: you must specify field if you specify value")
      end
    end
  end
end
