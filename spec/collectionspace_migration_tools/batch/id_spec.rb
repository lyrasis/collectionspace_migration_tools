# frozen_string_literal: true

require_relative "../../spec_helper"

RSpec.describe CollectionspaceMigrationTools::Batch::Id do
  let(:klass) { described_class.new(str) }

  describe "validate" do
    let(:result) { klass.validate }

    context "with too-long id" do
      let(:str) { "organization23" }

      it "returns failure" do
        expect(result).to be_a(Dry::Monads::Failure)
        expect(result.failure).to eq("Batch ID must be 6 or fewer characters")
      end
    end

    context "with disallowed characters" do
      let(:str) { "per_1" }

      it "returns failure" do
        expect(result).to be_a(Dry::Monads::Failure)
        expect(result.failure).to eq("Batch ID must consist of only letters "\
                                     "and numbers")
      end
    end

    context "when ok" do
      let(:str) { "co1" }

      it "returns success" do
        expect(result).to be_a(Dry::Monads::Success)
        expect(result.value!).to eq(str)
      end
    end
  end
end
