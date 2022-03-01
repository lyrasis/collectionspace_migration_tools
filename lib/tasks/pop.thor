# frozen_string_literal: true

require 'dry/monads'
require 'thor'

# tasks targeting CS XML payloads
class Pop < Thor
  include CMT::CliHelpers
  include Dry::Monads[:result]

  desc 'all', 'populate caches with everything'
  def all
    invoke 'pop:auth:all'
    invoke :vocabs
    invoke :obj
    invoke 'pop:proc:all'
  end

  desc 'obj', 'populate csid cache with objects'
  def obj
    query = CMT::QueryBuilder::Object.call
    query_and_populate(['object'], [query], 'Objects', :csid)
    CMT.safe_exit
  end
  
  desc 'terms', 'populate caches with all authority and vocabulary terms'
  def terms
    invoke 'pop:auth:all'
    invoke :vocabs
  end

  desc 'vocabs', 'populate caches with all vocabulary terms'
  def vocabs
    query = CMT::QueryBuilder::Vocabulary.call
    query_and_populate(['vocab'], [query], 'VocabTerms')
    CMT.safe_exit
  end
end

