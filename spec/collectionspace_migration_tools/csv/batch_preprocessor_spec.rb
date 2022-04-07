# frozen_string_literal: true

require_relative '../../spec_helper'

RSpec.describe CollectionspaceMigrationTools::Csv::BatchPreprocessor do
  let(:csv_path){ File.join(Bundler.root.to_s, 'spec', 'support', 'fixtures', 'csv', csv_name) }
  let(:row){ CMT::Csv::FirstRowGetter.call(csv_path).value! }
  let(:handler){ setup_handler('collectionobject')}
  let(:batch){ instance_double('CollectionspaceMigrationTools::Csv::BatchProcessor') }
  
  describe '#call' do
    let(:result){ described_class.call(handler: handler, first_row: row, batch: batch) }

    context 'when missing a header' do
      let(:csv_name){ 'missing_header.csv' }
      
      it 'is Failure', :aggregate_failures do
        expect(result).to be_a(Dry::Monads::Failure)
        expect(result.failure).to eq('1 field(s) lack a header value')
      end
    end

    context 'when missing a required field' do
      let(:csv_name){ 'required_field_missing.csv' }
      
      it 'is Failure', :aggregate_failures do
        expect(result).to be_a(Dry::Monads::Failure)
        expect(result.failure).to eq('required field missing: objectnumber must be present')
      end
    end
  end
end
