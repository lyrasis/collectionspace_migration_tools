# frozen_string_literal: true

require_relative '../../spec_helper'

RSpec.describe CollectionspaceMigrationTools::Csv::BatchProcessor do
  let(:csv_name){ 'unknown_header.csv' }
  let(:csv_path){ File.join(Bundler.root.to_s, 'spec', 'support', 'fixtures', 'csv', csv_name) }
  let(:rectype){ 'collectionobject' }
  let(:action){ 'create' }
  let(:klass){ CMT::Csv::BatchProcessorPreparer.new(csv_path: csv_path, rectype: rectype, action: action).call.value! }

  describe '#add_unknown_field' do
    it 'adds value to unknown_fields', :aggregate_failures do
      expect(klass.unknown_fields).to be_empty
      klass.add_unknown_field('miscfield')
      expect(klass.unknown_fields).to eq(['miscfield'])
    end
  end
  
  describe '#preprocess' do
    let(:result){ klass.preprocess }

  end
end

