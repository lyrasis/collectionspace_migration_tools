# frozen_string_literal: true

require_relative '../../../spec_helper'

RSpec.describe CollectionspaceMigrationTools::Batch::Csv::Reader do
  let(:klass){ described_class.new(data) }
  let(:data) do
"\"id\",\"source_csv\",\"mappable_rectype\",\"action\",\"rec_ct\",\"mapped?\",\"dir\",\"map_errs\",\"map_oks\",\"map_warns\",\"uploaded?\",\"upload_errs\",\"upload_oks\",\"batch_prefix\",\"ingest_checked?\",\"ingest_errs\",\"ingest_oks\",\"duplicates_checked?\",\"duplicates\",\"done?\"\n\"co1\",\"foo.csv\",\"collectionobject\",\"create\",123,,,,,,,,,,,,,,,\n\"co2\",\"bar.csv\",\"collectionobject\",\"update\",123,,,,,,,,,,,,,,,\n\"acq1\",\"baz.csv\",\"acquisition\",\"create\",10,,,,,,,,,,,,,,,\n"
  end
  
  describe '#to_monad' do
    let(:result){ klass.to_monad }
    context 'with no duplicate ids and headers up to date' do

      it 'is success', :aggregate_failures do
        expect(result).to be_a(Dry::Monads::Success)
        expect(result.value!).to be_a(described_class)
      end
    end
    
    context 'with duplicate ids in data' do
      let(:data) do
"\"id\",\"source_csv\",\"mappable_rectype\",\"action\",\"rec_ct\",\"mapped?\",\"dir\",\"map_errs\",\"map_oks\",\"map_warns\",\"uploaded?\",\"upload_errs\",\"upload_oks\",\"batch_prefix\",\"ingest_checked?\",\"ingest_errs\",\"ingest_oks\",\"duplicates_checked?\",\"duplicates\",\"done?\"\n\"co1\",\"foo.csv\",\"collectionobject\",\"create\",10,,,,,,,,,,,,,,,\n\"co1\",\"bar.csv\",\"acquisition\",\"create\",10,,,,,,,,,,,,,,,\n"
      end

      it 'is failure', :aggregate_failures do
        expect(result).to be_a(Dry::Monads::Failure)
        msg = 'Batch ids are not unique. Please manually edit and save CSV where info about batches is recorded.'
        expect(result.failure).to eq(msg)
      end
    end

    context 'with out of date headers' do
      let(:data) do
"\"id\",\"source_csv\",\"mappable_rectype\",\"action\",\"rec_ct\",\"mapped?\",\"map_oks\",\"map_warns\",\"uploaded?\",\"upload_errs\",\"upload_oks\",\"batch_prefix\",\"ingest_checked?\",\"ingest_errs\",\"ingest_oks\",\"duplicates_checked?\",\"duplicates\",\"done?\"\n\"co1\",\"foo.csv\",\"collectionobject\",\"create\",10,,,,,,,,,,,,,\n\"acq1\",\"bar.csv\",\"acquisition\",\"create\",10,,,,,,,,,,,,,\n"
      end

      it 'is failure', :aggregate_failures do
        expect(result).to be_a(Dry::Monads::Failure)
        msg = 'Batch CSV headers are not up-to-date, so batch workflows may fail unexpectedly. Run `thor batches:fix_csv` to fix'
        expect(result.failure).to eq(msg)
      end
    end
  end
  
  describe '#find_batch' do
    let(:result){ klass.find_batch(id) }
    let(:id){ 'co2' }
    
    context 'when single batch found' do
      it 'returns Success containing batch row', :aggregate_failures do
        expect(result).to be_a(Dry::Monads::Success)
        expect(result.value!).to be_a(CSV::Row)
      end
    end

    context 'when no batch found' do
      let(:id){ 'co99' }

      it 'returns failure', :aggregate_failures do
        expect(result).to be_a(Dry::Monads::Failure)
        expect(result.failure).to eq("No batch with id: #{id}")
      end
    end
  end
  
  describe '#ids' do
    let(:result){ klass.ids }

    it 'returns Array of ids' do
      expect(result).to eq(['co1', 'co2', 'acq1'])
    end
  end
end
