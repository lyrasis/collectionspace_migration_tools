# frozen_string_literal: true

require "fileutils"

require_relative "../../spec_helper"

RSpec.describe CollectionspaceMigrationTools::ArchiveCsv::Fixer do
  subject { described_class.new(headers: %w[id source_csv new_col rec_ct]) }

  let(:expected) do
    <<~CSV
      id,source_csv,new_col,rec_ct
      1,csv,,10
    CSV
  end
  let(:extra_header_data) do
    <<~CSV
      id,source_csv,action,new_col,rec_ct
      1,csv,create,,10
      2,tsv,update,,5
    CSV
  end
  let(:missing_header_data) do
    <<~CSV
      id,source_csv,rec_ct
      1,csv,10
      2,tsv,5
    CSV
  end

  let(:result_data_compare) do
    new_table = CMT::ArchiveCsv.parse.value!
    expected_table = CSV.parse(expected, headers: true)
    # puts 'EXPECTED'
    # puts expected
    # puts 'RESULT'
    # puts new_table
    new_table == expected_table
  end

  describe "#call" do
    let(:result) { subject.call }
    after(:each) { FileUtils.rm(CMT::ArchiveCsv.path, force: true) }

    it "with current format, returns success message, no changes" do
      headers = %w[id source_csv new_col rec_ct]
      row = [1, "csv", nil, 10]
      build_test_archive_csv(headers: headers, row: row)

      expect(result).to be_a(Dry::Monads::Success)
      expect(result.value!).to eq("Nothing to fix!")
      expect(result_data_compare).to be true
    end

    it "reorders columns" do
      headers = %w[id rec_ct source_csv new_col]
      row = [1, 10, "csv", nil]
      build_test_archive_csv(headers: headers, row: row)

      expect(result).to be_a(Dry::Monads::Success)
      expect(result.value!).to eq("Updated CSV columns")
      expect(result_data_compare).to be true
    end

    it "when column removed, deletes that column" do
      headers = %w[id source_csv action new_col rec_ct]
      row = [1, "csv", "update", nil, 10]
      build_test_archive_csv(headers: headers, row: row)

      expect(result).to be_a(Dry::Monads::Success)
      expect(result.value!).to eq("Updated CSV columns")
      expect(result_data_compare).to be true
    end

    it "when column added, adds that column" do
      headers = %w[id source_csv rec_ct]
      row = [1, "csv", 10]
      build_test_archive_csv(headers: headers, row: row)

      expect(result).to be_a(Dry::Monads::Success)
      expect(result.value!).to eq("Updated CSV columns")
      expect(result_data_compare).to be true
    end
  end
end
