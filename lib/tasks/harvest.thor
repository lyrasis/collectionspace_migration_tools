# frozen_string_literal: true

require "thor"

class Harvest < Thor
  desc "rt RECTYPE", "harvest XML records of RECTYPE from CollectionSpace"
  def rt(rectype)
    CMT::Harvester::Harvester.call rec_type: rectype
  end
end
