# frozen_string_literal: true

require "thor"

class Harvest < Thor
  desc "rt RECTYPE", "harvest XML records of RECTYPE from CollectionSpace"
  def rt(rectype)
    CMT::Harvester::Harvester.call(rec_type: rectype)
      .either(
        ->(success) do
          puts success
          exit(0)
        end,
        ->(failure) do
          puts failure
          exit(1)
        end
      )
  end
end
