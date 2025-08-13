# frozen_string_literal: true


require_relative "../../../../spec_helper"

RSpec.describe CMT::Cache::Populate::Types::Procedures do
  class Cash
    def procedure_key(type, id) = "#{type}:#{id}"
  end

  class Foo
    include CMT::Cache::Populate::Types::Procedures

    attr_reader :cache, :cache_type

    def initialize(cache_type)
      @cache = Cash.new
      @cache_type = cache_type
    end
  end

  subject(:klass) { Foo.new(:csid) }

  describe "#signature" do
    let(:result) { klass.signature(row) }

    context "with exit" do
      let(:row) do
        {"type" => "exit", "id" => "1", "csid" => "123"}
      end

      it "returns as expected" do
        expect(result).to eq(["exits", "1", "123"])
      end
    end
  end

  describe "#key_val" do
    let(:result) { klass.key_val(row) }

    context "with exit" do
      let(:row) do
        {"type" => "exit", "id" => "1", "csid" => "123"}
      end

      it "returns as expected" do
        expect(result).to eq(["exits:1", "csid"])
      end
    end
  end
end
