# frozen_string_literal: true

require_relative "../../spec_helper"

RSpec.describe CMT::ArchiveCsv::Checker do
  subject(:checker) { described_class.new(headers: headers) }
  let(:old_headers) { %w[id source_csv] }
  let(:headers) { old_headers + ["new_col"] }

  describe "#call" do
    let(:result) { checker.call }

    context "when file does not exist" do
      before(:each) do
        CMT.config.client.base_dir = File.join(Bundler.root, "tmp")
        FileUtils.rm(CMT::ArchiveCsv.path, force: true)
      end
      after(:each) { FileUtils.rm(CMT::ArchiveCsv.path, force: true) }

      it "returns failure" do
        expect(result).to be_a(Dry::Monads::Failure)
        expect(result.failure).to eq(CMT::ArchiveCsv.file_check_failure_msg)
      end
    end

    context "when file exists with current headers" do
      before(:each) { build_test_archive_csv(headers: headers) }
      after(:each) { FileUtils.rm(CMT::ArchiveCsv.path, force: true) }

      it "returns success" do
        expect(result).to be_a(Dry::Monads::Success)
      end
    end

    context "when file exists with outdated headers" do
      before(:each) { build_test_archive_csv(headers: old_headers) }
      after(:each) { FileUtils.rm(CMT::ArchiveCsv.path, force: true) }

      it "returns failure" do
        expect(result).to be_a(Dry::Monads::Failure)
        expect(result.failure).to eq(
          checker.send(:header_check_failure_msg)
        )
      end
    end
  end
end
