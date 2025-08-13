# frozen_string_literal: true

require "thor"

class Harvest < Thor
  include CMT::Harvester

  class_option :debug, desc: "Sets up debug mode", aliases: ["-d"],
    type: :boolean

  desc "rt RECTYPE", "harvest XML records of RECTYPE from CollectionSpace"
  def rt(rectype)
    CMT::Harvester::Harvester.call rec_type: rectype
  end
end
