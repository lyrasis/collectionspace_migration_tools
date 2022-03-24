# frozen_string_literal: true

require_relative '../../spec_helper'

RSpec.describe CollectionspaceMigrationTools::Csv::UnknownFieldsCheck do
  let(:csv_path){ File.join(Bundler.root.to_s, 'spec', 'support', 'fixtures', 'csv', csv_name) }
  let(:row){ CMT::Csv::FirstRowGetter.call(csv_path).value! }
  let(:handler){ setup_handler('collectionobject')}
  
  describe '#call' do
    let(:klass){ described_class.new(handler, row) }
    let(:called){ klass.call }

    context 'when unknown field present' do
      let(:csv_name){ 'unknown_header.csv' }
      
      it 'is Success and warn to STDOUT', :aggregate_failures do
        msg = 'WARNING: 1 unknown fields in data will be ignored: miscfield'
        expect(klass).to receive(:warn).with(msg)
        expect(called).to be_a(Dry::Monads::Success)
      end
    end

    context 'when no unknown fields present' do
      let(:csv_name){ 'new_terms.csv' }
      
      it 'is Success', :aggregate_failures do
        expect(called).to be_a(Dry::Monads::Success)
      end
    end
  end
end

