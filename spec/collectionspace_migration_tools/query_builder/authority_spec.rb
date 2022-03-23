# frozen_string_literal: true

require_relative '../../spec_helper'

RSpec.describe CollectionspaceMigrationTools::QueryBuilder::Authority do
  describe '.initialize' do
    let(:rectype){ 'unknown' }
    let(:result){ described_class.new(rectype) }

    context 'with unknown rectype' do
      it 'raises UnknownTypeError' do
        errclass = CMT::QB::UnknownTypeError
        expect{ result }.to raise_error(errclass)
      end
    end
  end

  describe '#call' do
    let(:result){ described_class.new(rectype).call }
    let(:rectype){ 'citation' }

    it 'returns expected sql' do
      expected = "with auth_vocab_csid as (\nselect acv.id, h.name as csid, acv.shortidentifier from citationauthorities_common acv\ninner join hierarchy h on acv.id = h.id\n),\nterms as (\nselect h.parentid as id, tg.termdisplayname from hierarchy h\ninner join citations_common ac on ac.id = h.parentid and h.name like '%TermGroupList' and pos = 0\ninner join citationtermgroup tg on h.id = tg.id\n)\n\nselect 'citationauthorities' as type, acv.shortidentifier as subtype, t.termdisplayname as term, ac.refname, h.name as csid\nfrom citations_common ac\ninner join misc on ac.id = misc.id and misc.lifecyclestate != 'deleted'\ninner join auth_vocab_csid acv on ac.inauthority = acv.csid\ninner join terms t on ac.id = t.id\ninner join hierarchy h on ac.id = h.id\n"
      expect(result).to eq(expected)
    end
  end
  
  describe '#service_config' do
    let(:result){ described_class.new(rectype).send(:service_config) }
    let(:rectype){ 'citation' }

    it 'returns service config hash', :aggregate_failures do
      expect(result).to be_a(Hash)
      expect(result.fetch(:ns_prefix, 'nope')).to eq('citations')
    end
  end

  describe '#service_type' do
    let(:result){ described_class.new(rectype).send(:service_type) }
    context 'with rectype following normal pattern (citation)' do
      let(:rectype){ 'citation' }

      it 'returns citationauthorities' do
        expect(result).to eq('citationauthorities')
      end
    end

    context 'with organization' do
      let(:rectype){ 'organization' }

      it 'returns orgauthorities' do
        expect(result).to eq('orgauthorities')
      end
    end

    context 'with taxon' do
      let(:rectype){ 'taxon' }

      it 'returns taxonomyauthority' do
        expect(result).to eq('taxonomyauthority')
      end
    end
  end

  describe '#term_table' do
    let(:result){ described_class.new(rectype).send(:term_table) }
    let(:rectype){ 'citation' }

    it 'returns expected table name' do
      expect(result).to eq('citations_common')
    end
  end

  describe '#term_group_table' do
    let(:result){ described_class.new(rectype).send(:term_group_table) }
    let(:rectype){ 'citation' }

    it 'returns expected table name' do
      expect(result).to eq('citationtermgroup')
    end
  end

  describe '#vocab_table' do
    let(:result){ described_class.new(rectype).send(:vocab_table) }
    let(:rectype){ 'citation' }

    it 'returns expected table name' do
      expect(result).to eq('citationauthorities_common')
    end
  end
end
