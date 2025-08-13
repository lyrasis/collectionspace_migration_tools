# frozen_string_literal: true

require_relative "../../spec_helper"

RSpec.describe CollectionspaceMigrationTools::Entity::Relation do
  subject(:relation) { described_class.new(str) }

  context "with nonhierarchicalrelationship" do
    let(:str) { "nonhierarchicalrelationship" }

    it "returns as expected" do
      expect(relation).to be_a(described_class)
      expect(relation.name).to eq("nonhierarchicalrelationship")
      expect(relation.subtype).to be_nil
      expect(relation.status.success?).to be true
      expect(relation.service_path).to eq("relations")
      expect(relation.service_path_full).to eq("relations")
    end
  end
end
