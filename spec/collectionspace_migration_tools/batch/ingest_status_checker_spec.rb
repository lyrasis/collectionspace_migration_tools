# frozen_string_literal: true

require_relative "../../spec_helper"

RSpec.describe CollectionspaceMigrationTools::Batch::IngestStatusChecker do
  let(:lister) { double }
  let(:checks) { 1 }
  let(:rechecks) { 1 }
  let(:klass) do
    described_class.new(lister: lister, wait: 0.1, checks: checks,
      rechecks: rechecks)
  end

  describe "#call" do
    let(:result) { klass.call }
    context "no objects left on initial check" do
      it "behaves as expected" do
        allow(klass).to receive(:get_size).exactly(1).times.and_return(Dry::Monads::Success(0))
        expect(result).to be_a(Dry::Monads::Success)
      end
    end

    context "with single check" do
      context "when no objects left on check" do
        it "behaves as expected" do
          sizes = [
            5, # initial
            0 # first/only check = 0 so no recheck needed
          ]
          allow(klass).to receive(:get_size).exactly(sizes.length).times {
                            Dry::Monads::Success(sizes.shift)
                          }
          expect(result).to be_a(Dry::Monads::Success)
        end
      end

      context "when count different on check" do
        it "behaves as expected", :aggregate_failures do
          sizes = [
            5, # initial
            3 # first/only check = changed, so failure
          ]
          allow(klass).to receive(:get_size).exactly(sizes.length).times {
                            Dry::Monads::Success(sizes.shift)
                          }
          expect(result).to be_a(Dry::Monads::Failure)
          expect(result.failure).to eq("Ingest is still being processed: 3 remaining")
        end
      end

      context "when same on check" do
        context "when same on single recheck" do
          it "behaves as expected" do
            sizes = [
              5, # initial
              5, # first/only check = same, recheck needed
              5 # first/only recheck = same = success
            ]
            allow(klass).to receive(:get_size).exactly(sizes.length).times {
                              Dry::Monads::Success(sizes.shift)
                            }
            expect(result).to be_a(Dry::Monads::Success)
          end
        end

        context "with 5 rechecks" do
          let(:rechecks) { 5 }

          context "with third recheck = 0" do
            it "behaves as expected" do
              sizes = [
                5, # initial
                5, # first/only check = same, recheck needed
                5, # recheck 1
                5, # recheck 2
                0 # recheck 3, only success because 0
              ]
              allow(klass).to receive(:get_size).exactly(sizes.length).times {
                                Dry::Monads::Success(sizes.shift)
                              }
              expect(result).to be_a(Dry::Monads::Success)
            end
          end

          context "with third recheck = 3" do
            it "behaves as expected", :aggregate_failures do
              sizes = [
                5, # initial
                5, # first/only check = same, recheck needed
                5, # recheck 1
                5, # recheck 2
                3 # recheck 3, failure because change
              ]
              allow(klass).to receive(:get_size).exactly(sizes.length).times {
                                Dry::Monads::Success(sizes.shift)
                              }
              expect(result).to be_a(Dry::Monads::Failure)
              expect(result.failure).to eq("Ingest is still being processed: 3 remaining")
            end
          end
        end
      end
    end

    context "with 5 checks" do
      let(:checks) { 5 }

      context "when no objects left on second check" do
        it "behaves as expected" do
          sizes = [
            5, # initial
            3, # on first check, changing
            0  # empty on second check
          ]
          allow(klass).to receive(:get_size).exactly(sizes.length).times {
                            Dry::Monads::Success(sizes.shift)
                          }
          expect(result).to be_a(Dry::Monads::Success)
        end
      end

      context "when objects count stabilizes on third check" do
        context "when recheck is the same" do
          it "behaves as expected" do
            sizes = [
              5, # initial
              4, # on first check, changing
              3, # check 2, changing
              3, # check 3, tentatively done
              3 # recheck, good!
            ]
            allow(klass).to receive(:get_size).exactly(sizes.length).times {
                              Dry::Monads::Success(sizes.shift)
                            }
            expect(result).to be_a(Dry::Monads::Success)
          end
        end

        context "when recheck is different" do
          let(:checks) { 5 }
          it "behaves as expected", :aggregate_failures do
            sizes = [
              5, # initial
              4, # on first check, changing
              3, # check 2, changing
              3, # check 3, tentatively done
              2 # recheck, no!
            ]
            allow(klass).to receive(:get_size).exactly(sizes.length).times {
                              Dry::Monads::Success(sizes.shift)
                            }
            expect(result).to be_a(Dry::Monads::Failure)
            expect(result.failure).to eq("Ingest is still being processed: 2 remaining")
          end
        end
      end

      context "when count does not stabilize" do
        it "behaves as expected", :aggregate_failures do
          sizes = [
            9, # initial
            8, # on first check, changing
            7, # check 2, changing
            6, # check 3
            5, # check 4
            4 # check 5
          ]
          allow(klass).to receive(:get_size).exactly(sizes.length).times {
                            Dry::Monads::Success(sizes.shift)
                          }
          expect(result).to be_a(Dry::Monads::Failure)
          expect(result.failure).to eq("Ingest is still being processed: 4 remaining")
        end
      end
    end
  end
end
