# frozen_string_literal: true

require "thor"

class Harvest < Thor
  include CMT::CliHelpers

  desc "rt RECTYPE", "harvest XML records of RECTYPE from CollectionSpace"
  def rt(rectype)
    report_result(CMT::Harvester::Harvester.call(rec_type: rectype))
  end
end
