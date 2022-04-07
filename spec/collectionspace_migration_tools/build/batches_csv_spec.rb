# frozen_string_literal: true

require 'fileutils'
require_relative '../../spec_helper'

RSpec.describe CollectionspaceMigrationTools::Build::BatchesCsv do
  before(:all){ CMT.config.client.batch_csv = File.join(Bundler.root, 'tmp', 'batches.csv') }

  let(:klass){ described_class.new }
  let(:path){ CMT.config.client.batch_csv }
  
  describe '#call' do
    let(:result){ klass.call }
    
    context 'when file already exists and headers match' do
      before(:all) do
        headers = described_class.headers
        CSV.open(CMT.config.client.batch_csv, 'w') do |csv|
          csv << headers
          csv << ['co1', 'foo', 'bar', 'create', 10]
        end
      end
      after(:all){ FileUtils.rm(CMT.config.client.batch_csv) if File.exists?(CMT.config.client.batch_csv)}

      it 'notifies of existence and does not change file', :aggregate_failures do
        expect{ result }.to output("#{path} already exists; leaving it alone\n").to_stdout
        expect(result).to be_a(Dry::Monads::Success)
      end
    end

    context 'when file already exists and headers do not match' do
      before(:all) do
        headers = %w[id source_csv rectype action rec_ct]
        CSV.open(CMT.config.client.batch_csv, 'w', headers: headers, write_headers: true) do |csv|
          csv << ['co1', 'foo', 'bar', 'create', 10]
        end
      end
      after(:all){ FileUtils.rm(CMT.config.client.batch_csv) if File.exists?(CMT.config.client.batch_csv)}

      it 'notifies of existence and warns of out of date headers', :aggregate_failures do
        msg = 'WARNING: Batch CSV headers are not up-to-date. Run `thor batches:update_csv` to fix'
        expect(klass).to receive(:warn).with(msg)
        expect{ result }.to output("#{path} already exists; leaving it alone\n").to_stdout
        expect(result).to be_a(Dry::Monads::Success)
      end
    end

    context 'when file does not exist' do
      before(:all){ FileUtils.rm(CMT.config.client.batch_csv) if File.exists?(CMT.config.client.batch_csv)}
      after(:all){ FileUtils.rm(CMT.config.client.batch_csv) if File.exists?(CMT.config.client.batch_csv)}

      it 'creates file', :aggregate_failures do
        result
        expect(File.exists?(path)).to be true
      end
    end
  end
end
