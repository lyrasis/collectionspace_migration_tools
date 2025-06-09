# frozen_string_literal: true

require "thor"
require "thor/hollaback"

# Tasks to populate caches
class Pop < Thor
  include CMT::CliHelpers::Pop

  class_option :debug, desc: "Sets up debug mode", aliases: ["-d"],
    type: :boolean
  class_around :safe_db

  desc "all", "populate caches with everything"
  def all
    start_time = Time.now

    cleared = CMT::Caches::Clearer.call
    if cleared.failure?
      puts cleared
      exit(1)
    end

    query_and_populate(CMT::Entity.authorities)
    query_and_populate([CMT::Entity::Vocabulary.new])
    query_and_populate([CMT::Entity::Collectionobject.new])
    query_and_populate(CMT::Entity.procedures)
    query_and_populate(CMT::Entity.relations, :csid)

    puts "Total time: #{Time.now - start_time}"
  end

  desc "obj", "populate csid cache with objects"
  def obj
    query_and_populate([CMT::Entity::Collectionobject.new])
  end

  desc "terms", "populate caches with all authority and vocabulary terms"
  def terms
    query_and_populate(CMT::Entity.authorities)
    query_and_populate([CMT::Entity::Vocabulary.new])
  end

  desc "vocabs", "populate caches with all vocabulary terms"
  def vocabs
    query_and_populate([CMT::Entity::Vocabulary.new])
  end
end
