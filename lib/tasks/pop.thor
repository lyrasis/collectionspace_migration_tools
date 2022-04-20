# frozen_string_literal: true

require 'thor'
require 'thor/hollaback'

# tasks targeting CS XML payloads
class Pop < Thor
  include CMT::CliHelpers::Pop
  
  class_option :debug, desc: 'Sets up debug mode', aliases: ['-d'], type: :boolean
  class_around :safe_db

  desc 'all', 'populate caches with everything'
  def all
    start_time = Time.now
    
    invoke 'caches:clear'
    query_and_populate(authorities)
    query_and_populate([CMT::Entity::Vocabulary.new])
    query_and_populate([CMT::Entity::Collectionobject.new])
    query_and_populate(procedures)
    query_and_populate(relations, :csid)

    puts "Total time: #{Time.now - start_time}"
  end

  desc 'obj', 'populate csid cache with objects'
  def obj
    query_and_populate([CMT::Entity::Collectionobject.new])
  end
  
  desc 'terms', 'populate caches with all authority and vocabulary terms'
  def terms
    query_and_populate(authorities)
    query_and_populate([CMT::Entity::Vocabulary.new])
  end

  desc 'vocabs', 'populate caches with all vocabulary terms'
  def vocabs
    query_and_populate([CMT::Entity::Vocabulary.new])
  end
end
