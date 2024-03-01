# frozen_string_literal: true

require "dry/monads"
require "thor"

# Miscellaneous commands on the CollectionSpace instance
class Cspace < Thor
  include Dry::Monads[:result]

  desc "reindex", "initiate fulltext reindex of the instance"
  long_desc <<-LONGDESC
    Posts to /cspace-services/index/elasticsearch, triggering fulltext
    reindexing of the CollectionSpace instance.

    NOTE: There is no indication of when the reindexing task is complete. A
    success indicates that the process has been initiated.
  LONGDESC
  def reindex
    CMT::Cspace::Reindexer.call
      .either(
        ->(success) do
          puts "Reindexing successfully initiated"
          exit(0)
        end,
        ->(failure) do
          puts failure
          exit(1)
        end
      )
  end
end
