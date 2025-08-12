# frozen_string_literal: true

require_relative "../../spec_helper"

RSpec.describe CollectionspaceMigrationTools::Entity::Procedure do
  subject(:procedure) { described_class.new(str) }

  context "with exit" do
    let(:str) { "exit" }

    it "returns as expected" do
      expect(procedure).to be_a(described_class)
      expect(procedure.name).to eq("exit")
      expect(procedure.subtype).to be_nil
      expect(procedure.status.success?).to be true
      expect(procedure.service_path).to eq("exits")
      expect(procedure.service_path_full).to eq("exits")
    end
  end
end
