# frozen_string_literal: true

require "fileutils"
require_relative "../../../spec_helper"

RSpec.describe CollectionspaceMigrationTools::Batch::Csv::Creator do
  let(:klass) { described_class.new }
  let(:path) { CMT.config.client.batch_csv }

  describe "#call" do
    let(:result) { klass.call }

    context "when file already exists" do
      after(:all) do
        next unless File.exist?(CMT.config.client.batch_csv)

        FileUtils.rm(CMT.config.client.batch_csv)
      end

      it "notifies of existence and does not change file" do
        CMT.config.client.batch_csv = File.join(
          Bundler.root, "tmp", "batches.csv"
        )
        headers = CMT::Batch::Csv::Headers.all_headers
        CSV.open(CMT.config.client.batch_csv, "w") do |csv|
          csv << headers
          csv << ["co1", "foo", "bar", "create", 10]
        end

        expect do
          result
        end.to output("#{path} already exists; leaving it alone\n").to_stdout
        expect(result).to be_a(Dry::Monads::Success)
      end
    end

    context "when file does not exist" do
      before(:all) do
        FileUtils.rm(CMT.config.client.batch_csv) if File.exist?(CMT.config.client.batch_csv)
      end
      after(:all) do
        FileUtils.rm(CMT.config.client.batch_csv) if File.exist?(CMT.config.client.batch_csv)
      end

      it "creates file" do
        result
        expect(File.exist?(path)).to be true
      end
    end
  end
end
