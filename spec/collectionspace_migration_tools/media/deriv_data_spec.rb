# frozen_string_literal: true

require_relative '../../spec_helper'

RSpec.describe CollectionspaceMigrationTools::Media::DerivData do
  subject(:data){ described_class.new(blobcsid: 'foo', response: response) }

  context 'with all derivs' do
    let(:response) do
      {'abstract_common_list'=>
       {"pageNum"=>"0",
        "pageSize"=>"0",
        "itemsInPage"=>"0",
        "totalItems"=>"0",
        "fieldsReturned"=>"csid|uri|name|mimeType|encoding|length",
        "list_item"=>
          [{"uri"=>"/blobs/foo/derivatives/Small/content",
            "name"=>"Small_2016.007.353.A.jpg",
            "mimeType"=>"image/jpeg", "length"=>"212221"},
           {"uri"=>"/blobs/foo/derivatives/Medium/content",
            "name"=>"Medium_2016.007.353.A.jpg",
            "mimeType"=>"image/jpeg", "length"=>"488692"},
           {"uri"=>"/blobs/foo/derivatives/Thumbnail/content",
            "name"=>"Thumbnail_2016.007.353.A.jpg",
            "mimeType"=>"image/jpeg", "length"=>"68971"},
           {"uri"=>"/blobs/foo/derivatives/OriginalJpeg/content",
            "name"=>"OriginalJpeg_2016.007.353.A.jpg",
            "mimeType"=>"image/jpeg", "length"=>"7449471"},
           {"uri"=>"/blobs/foo/derivatives/FullHD/content",
            "name"=>"FullHD_2016.007.353.A.jpg",
            "mimeType"=>"image/jpeg", "length"=>"1541086"}]}}
    end

    it 'behaves as expected' do
      expect(data.deriv_ct).to eq(5)
      exderivs = %w[small medium thumbnail originaljpeg fullhd]
      expect(data.derivs.sort).to eq(exderivs.sort)
      expect(data.small?).to be true
      expect(data.medium?).to be true
      expect(data.thumbnail?).to be true
      expect(data.originaljpeg?).to be true
      expect(data.fullhd?).to be true
    end
  end

  context 'when missing thumbnail' do
    let(:response) do
      {'abstract_common_list'=>
       {"pageNum"=>"0",
        "pageSize"=>"0",
        "itemsInPage"=>"0",
        "totalItems"=>"0",
        "fieldsReturned"=>"csid|uri|name|mimeType|encoding|length",
        "list_item"=>
          [{"uri"=>"/blobs/foo/derivatives/Small/content",
            "name"=>"Small_2016.007.353.A.jpg",
            "mimeType"=>"image/jpeg", "length"=>"212221"},
           {"uri"=>"/blobs/foo/derivatives/Medium/content",
            "name"=>"Medium_2016.007.353.A.jpg",
            "mimeType"=>"image/jpeg", "length"=>"488692"},
           {"uri"=>"/blobs/foo/derivatives/OriginalJpeg/content",
            "name"=>"OriginalJpeg_2016.007.353.A.jpg",
            "mimeType"=>"image/jpeg", "length"=>"7449471"},
           {"uri"=>"/blobs/foo/derivatives/FullHD/content",
            "name"=>"FullHD_2016.007.353.A.jpg",
            "mimeType"=>"image/jpeg", "length"=>"1541086"}]}}
    end

    it 'behaves as expected' do
      expect(data.deriv_ct).to eq(4)
      exderivs = %w[small medium originaljpeg fullhd]
      expect(data.derivs.sort).to eq(exderivs.sort)
      expect(data.small?).to be true
      expect(data.medium?).to be true
      expect(data.thumbnail?).to be false
      expect(data.originaljpeg?).to be true
      expect(data.fullhd?).to be true
      derivhash = {
        'small'=>'y',
        'medium'=>'y',
        'thumbnail'=>nil,
        'originaljpeg'=>'y',
        'fullhd'=>'y',
        'deriv_ct'=>4
      }
      expect(data.to_h).to eq(derivhash)
    end
  end

  context 'when no derivs' do
    let(:response) do
      {"abstract_common_list"=>{
        "pageNum"=>"0",
        "pageSize"=>"0",
        "itemsInPage"=>"0",
        "totalItems"=>"0",
        "fieldsReturned"=>"csid|uri|name|mimeType|encoding|length"
        }
      }
    end

    it 'behaves as expected' do
      expect(data.deriv_ct).to eq(0)
      expect(data.derivs).to eq([])
      expect(data.small?).to be false
      expect(data.medium?).to be false
      expect(data.thumbnail?).to be false
      expect(data.originaljpeg?).to be false
      expect(data.fullhd?).to be false
    end
  end
end
