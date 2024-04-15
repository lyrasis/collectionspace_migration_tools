# frozen_string_literal: true

require "fileutils"
require_relative "../../spec_helper"

RSpec.describe CollectionspaceMigrationTools::ArchiveCsv::Creator do
  subject(:creator) { described_class.new }
  let(:path) { CMT::ArchiveCsv.path }

  describe "#call" do
    let(:result) { creator.call }

    context "when file already exists" do
      before(:each) { build_test_archive_csv }
      after(:each) do
        return unless CMT::ArchiveCsv.present?

        FileUtils.rm(CMT::ArchiveCsv.path)
      end

      it "notifies of existence and does not change file" do
        expect do
          result
        end.to output("#{path} already exists; leaving it alone\n").to_stdout
        expect(result).to be_a(Dry::Monads::Success)
      end
    end

    context "when file does not exist" do
      before(:each) { FileUtils.rm(CMT::ArchiveCsv.path, force: true) }
      after(:each) { FileUtils.rm(CMT::ArchiveCsv.path, force: true) }

      it "creates file" do
        result
        expect(File.exist?(CMT::ArchiveCsv.path)).to be true
      end
    end
  end
end
