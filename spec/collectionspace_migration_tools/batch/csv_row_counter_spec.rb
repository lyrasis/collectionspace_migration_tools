# frozen_string_literal: true

require_relative '../../spec_helper'

RSpec.describe CollectionspaceMigrationTools::Batch::CsvRowCounter do
  before(:all) do
    @test_csv = File.join(Bundler.root, 'tmp', 'test.csv')
    data = <<~CSV
a,b,c
d,,e
,f,g
h,,i
j,k,
l,,m
CSV
    File.open(@test_csv, 'w'){ |file| file << data }
  end
  after(:all){ FileUtils.rm(@test_csv) if File.exists?(@test_csv) }
  
  let(:klass){ described_class.new(@test_csv) }

  describe '#call' do
    context 'with no field given' do
      let(:result){ klass.call }
      it 'returns Success containing total row count', :aggregate_failures do
        expect(result).to be_a(Dry::Monads::Success)
        expect(result.value!).to eq(5)
      end
    end

    context 'with field given' do
      let(:result){ klass.call('b') }
      it 'returns Success containing count of rows where field is populated', :aggregate_failures do
        expect(result).to be_a(Dry::Monads::Success)
        expect(result.value!).to eq(2)
      end
    end
  end
end
