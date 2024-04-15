# frozen_string_literal: true

require_relative "../../spec_helper"

RSpec.describe CollectionspaceMigrationTools::Xml::ServicesApiActionChecker do
  let(:klass) { described_class.new(action) }

  describe "#call" do
    let(:result) { klass.call(response) }
    let(:response_new) do
      double(record_status: :new)
    end
    let(:response_existing) do
      double(record_status: :existing)
    end

    context "with given action = create" do
      let(:action) { "CREATE" }

      context "when rec status = new" do
        let(:response) { response_new }
        it "returns CREATE" do
          expect(response).not_to receive(:add_warning)
          expect(result).to be_a(Dry::Monads::Success)
          expect(result.value!).to eq("CREATE")
        end
      end

      context "when rec status = existing" do
        let(:response) { response_existing }
        it "returns UPDATE" do
          expect(response).to receive(:add_warning)
          expect(result).to be_a(Dry::Monads::Success)
          expect(result.value!).to eq("UPDATE")
        end
      end
    end

    context "with given action = update" do
      let(:action) { "UPDATE" }

      context "when rec status = new" do
        let(:response) { response_new }
        it "returns CREATE" do
          expect(response).to receive(:add_warning)
          expect(result).to be_a(Dry::Monads::Success)
          expect(result.value!).to eq("CREATE")
        end
      end

      context "when rec status = existing" do
        let(:response) { response_existing }
        it "returns UPDATE" do
          expect(response).not_to receive(:add_warning)
          expect(result).to be_a(Dry::Monads::Success)
          expect(result.value!).to eq("UPDATE")
        end
      end
    end

    context "with given action = delete" do
      let(:action) { "DELETE" }

      context "when rec status = new" do
        let(:response) { response_new }
        it "returns Failure" do
          expect(result).to be_a(Dry::Monads::Failure)
        end
      end

      context "when rec status = existing" do
        let(:response) { response_existing }
        it "returns DELETE" do
          expect(response).not_to receive(:add_warning)
          expect(result).to be_a(Dry::Monads::Success)
          expect(result.value!).to eq("DELETE")
        end
      end
    end
  end
end
