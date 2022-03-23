# frozen_string_literal: true

require_relative '../../spec_helper'

RSpec.describe CollectionspaceMigrationTools::Csv::BatchPreprocessor do
  let(:csv_path){ File.join(Bundler.root.to_s, 'spec', 'support', 'fixtures', 'csv', csv_name) }
  let(:row){ CMT::Csv::FirstRowGetter.call(csv_path).value! }
  let(:handler){ setup_handler('collectionobject')}
  
  describe '#call' do
    let(:result){ described_class.call(handler: handler, first_row: row) }

    context 'when missing a header' do
      let(:csv_name){ 'missing_header.csv' }
      
      it 'is Failure', :aggregate_failures do
        expect(result).to be_a(Dry::Monads::Failure)
        expect(result.failure).to eq('1 field(s) lack a header value')
      end
    end

    context 'when all headers present' do
      let(:csv_name){ 'unknown_header.csv' }
      
      it 'is Success', :aggregate_failures do
        expect(result).to be_a(Dry::Monads::Success)
        expect(result.value!).to be_a(CSV::Row)
      end
    end
  end
end

