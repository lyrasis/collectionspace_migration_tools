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
    invoke 'caches:clear'
    query_and_populate(*authority_args(authorities))
    query_and_populate(*vocab_args)
    query_and_populate(*object_args)
    query_and_populate(*procedure_args(procedures))
    query_and_populate(*relation_args('all'))
  end

  desc 'obj', 'populate csid cache with objects'
  def obj
    query_and_populate(*object_args)
  end
  
  desc 'terms', 'populate caches with all authority and vocabulary terms'
  def terms
    query_and_populate(*authority_args(authorities))
    query_and_populate(*vocab_args)
  end

  desc 'vocabs', 'populate caches with all vocabulary terms'
  def vocabs
    query_and_populate(*vocab_args)
  end
end