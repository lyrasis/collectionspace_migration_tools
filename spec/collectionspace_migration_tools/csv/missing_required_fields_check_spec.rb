# frozen_string_literal: true

require_relative '../../spec_helper'

RSpec.describe CollectionspaceMigrationTools::Csv::MissingRequiredFieldsCheck do
  let(:csv_path){ File.join(Bundler.root.to_s, 'spec', 'support', 'fixtures', 'csv', csv_name) }
  let(:row){ CMT::Csv::FirstRowGetter.call(csv_path).value! }
  let(:handler){ setup_handler('collectionobject')}
  
  describe '#call' do
    let(:result){ described_class.call(handler, row) }

    context 'when missing a required field' do
      let(:csv_name){ 'required_field_missing.csv' }
      
      it 'is Failure', :aggregate_failures do
        expect(result).to be_a(Dry::Monads::Failure)
        expect(result.failure).to eq('required field missing: objectnumber must be present')
      end
    end

    context 'when required field present' do
      let(:csv_name){ 'unknown_header.csv' }
      
      it 'is Success' do
        expect(result).to be_a(Dry::Monads::Success)
      end
    end
  end
end

