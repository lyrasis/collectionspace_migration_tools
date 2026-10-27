# frozen_string_literal: true

require "dry/monads"
require "thor"

# Miscellaneous commands on the CollectionSpace instance
class Cspace < Thor
  include CMT::CliHelpers
  include Dry::Monads[:result]

  desc "reindex", "initiate fulltext reindex of the instance"
  long_desc <<-LONGDESC
    Posts to /cspace-services/index/elasticsearch, triggering fulltext
    reindexing of the CollectionSpace instance.

    NOTE: There is no indication of when the reindexing task is complete. A
    success indicates that the process has been initiated.
  LONGDESC
  def reindex
    report_result(
      CMT::Cspace::Reindexer.call,
      successlogic: ->(_result) { puts "Reindexing successfully initiated" }
    )
  end
end
