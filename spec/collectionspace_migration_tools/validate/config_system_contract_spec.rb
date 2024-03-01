# frozen_string_literal: true

require_relative "../../spec_helper"

RSpec.describe CollectionspaceMigrationTools::Validate::ConfigSystemContract do
  let(:result) { described_class.new.call(config).to_monad }

  context "when missing system aws_profile" do
    let(:config) do
      data = sys_config_hash.dup
      data.delete(:aws_profile)
      data
    end

    it "returns Failure with expected message", :aggregate_failures do
      expect(result).to be_a(Dry::Monads::Failure)
      expect(result.failure.errors(full: true).to_h.values[0][0]).to eq(
        "aws_profile is missing"
      )
    end
  end
end
