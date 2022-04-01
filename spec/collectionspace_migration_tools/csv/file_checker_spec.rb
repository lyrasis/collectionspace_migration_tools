# frozen_string_literal: true

require_relative '../../spec_helper'

RSpec.describe CollectionspaceMigrationTools::Csv::FileChecker do
  let(:csv_path){ File.join(Bundler.root.to_s, 'spec', 'support', 'fixtures', 'csv', csv_name) }
  let(:row_getter){ CMT::Csv::FirstRowGetter.new(csv_path) }
  
  describe '#call' do
    let(:result){ described_class.new(csv_path, row_getter).call }

    context 'with non-existent file' do
      let(:csv_name){ 'foo.csv' }
      
      it 'is Failure', :aggregate_failures do
        expect(result).to be_a(Dry::Monads::Failure)
        expect(result.failure.message).to end_with('does not exist')
      end
    end

    context 'with file having BOM' do
      let(:csv_name){ 'excel_plain_resaved_utf-8.csv' }
      
      it 'is Success', :aggregate_failures do
        expect(result).to be_a(Dry::Monads::Success)
        success = result.value!
        expect(success[0]).to eq(csv_path)
        expect(success[1]).to be_a(CSV::Row)
      end
    end

    context 'with bad encoding' do
      let(:csv_name){ 'excel_plain.csv' }
      
      it 'is Failure', :aggregate_failures do
        expect(result).to be_a(Dry::Monads::Failure)
        expect(result.failure.message).to start_with('Invalid byte sequence in UTF-8')
      end
    end
  end
end

