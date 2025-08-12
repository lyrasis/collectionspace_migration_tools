# frozen_string_literal: true

require "thor"
require "thor/hollaback"

class Harvest < Thor
  include CMT::Harvester

  class_option :debug, desc: "Sets up debug mode", aliases: ["-d"],
    type: :boolean

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
