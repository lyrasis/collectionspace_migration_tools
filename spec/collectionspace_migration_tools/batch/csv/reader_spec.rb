# frozen_string_literal: true

require_relative '../../../spec_helper'

RSpec.describe CollectionspaceMigrationTools::Batch::Csv::Reader do
  let(:klass){ described_class.new(data) }
  let(:data) do
  <<~CSV
\"id\",\"source_csv\",\"mappable_rectype\",\"action\"\n\"co1\",\"/Users/kristina/data/fast_importer_testing/object_10.csv\",\"collectionobject\",\"create\"\n\"co2\",\"/Users/kristina/data/fast_importer_testing/object_10_2.csv\",\"collectionobject\",\"create\"\n\"co3\",\"/Users/kristina/data/fast_importer_testing/object_10.csv\",\"collectionobject\",\"create\"\n\"co4\",\"/Users/kristina/data/fast_importer_testing/object_10.csv\",\"collectionobject\",\"create\"
    CSV
  end
  
  describe '#to_monad' do
    let(:result){ klass.to_monad }
    context 'with no duplicate ids' do

      it 'is success', :aggregate_failures do
        expect(result).to be_a(Dry::Monads::Success)
        expect(result.value!).to be_a(described_class)
      end
    end
    
    context 'with duplicate ids in data' do
      let(:data) do
  <<~CSV
\"id\",\"source_csv\",\"mappable_rectype\",\"action\"\n\"co1\",\"/Users/kristina/data/fast_importer_testing/object_10.csv\",\"collectionobject\",\"create\"\n\"co1\",\"/Users/kristina/data/fast_importer_testing/object_10_2.csv\",\"collectionobject\",\"create\"\n\"co3\",\"/Users/kristina/data/fast_importer_testing/object_10.csv\",\"collectionobject\",\"create\"\n\"co4\",\"/Users/kristina/data/fast_importer_testing/object_10.csv\",\"collectionobject\",\"create\"
    CSV
      end

      it 'is failure', :aggregate_failures do
        expect(result).to be_a(Dry::Monads::Failure)
        msg = 'Batch ids are not unique. Please manually edit and save CSV where info about batches is recorded.'
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
      expect(result).to eq(['co1', 'co2', 'co3', 'co4'])
    end
  end
end
