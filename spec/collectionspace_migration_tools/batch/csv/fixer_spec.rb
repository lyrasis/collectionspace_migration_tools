# frozen_string_literal: true

require 'fileutils'

require_relative '../../../spec_helper'

RSpec.describe CollectionspaceMigrationTools::Batch::Csv::Fixer do
  before(:all) do

    FileUtils.touch(CMT.config.client.batch_csv)
    
    module CollectionspaceMigrationTools
      module Batch
        module Csv
          module Headers
            define_method(:orig_headers){ all_headers.dup }
            undef_method(:all_headers)
            define_method(:all_headers){ %w[id source_csv new_col rec_ct] }
          end
        end
      end
    end
  end

  after(:all) do
    module CollectionspaceMigrationTools
      module Batch
        module Csv
          module Headers
            undef_method(:all_headers)
            define_method(:all_headers){ orig_headers.dup }
            undef_method(:orig_headers)
          end
        end
      end
    end

    bcsv = CMT.config.client.batch_csv
    FileUtils.rm(bcsv) if File.exists?(bcsv)
  end
  
  let(:klass){ described_class.new(data) }
  let(:ok_data) do
    <<~CSV
id,source_csv,new_col,rec_ct
1,csv,new,10
2,tsv,new,5
    CSV
  end
  let(:extra_header_data) do
    <<~CSV
id,source_csv,action,new_col,rec_ct
1,csv,create,new,10
2,tsv,update,new,5
    CSV
  end
  let(:missing_header_data) do
    <<~CSV
id,source_csv,rec_ct
1,csv,10
2,tsv,5
    CSV
  end
  let(:result_data_compare) do
    new_table = CSV.parse(File.read(CMT.config.client.batch_csv), headers: true)
    expected = CSV.parse(ok_data, headers: true)
    new_table == expected
  end
  
  describe '#call' do
    let(:result){ klass.call }

    context 'with up-to-date format and full data' do
      let(:data){ ok_data }

      it 'returns as expected', :aggregate_failures do
        expect(result).to be_a(Dry::Monads::Success)
        expect(result.value!).to eq('Nothing to fix!')
        expect(result_data_compare).to be true
      end
    end

    context 'with extra_header' do
      let(:data){ extra_header_data }

      it 'returns as expected', :aggregate_failures do
        expect(result).to be_a(Dry::Monads::Success)
        expect(result.value!).to eq('Removed extra headers: action')
        expect(result_data_compare).to be true
      end
    end

    context 'with missing_header' do
      let(:data){ missing_header_data }

      it 'returns as expected', :aggregate_failures do
        expect(result).to be_a(Dry::Monads::Success)
        expect(result.value!).to eq('Added new headers: new_col')
        expect(result_data_compare).to be true
      end
    end
  end
end
