# frozen_string_literal: true

require 'dry/monads'
require 'thor'

# tasks targeting CS XML payloads
class Pop < Thor
  include CMT::Queryable
  include Dry::Monads[:result]

  desc 'vocabs', 'populate caches with all vocabulary terms'
  def vocabs
    begin
      query = CMT::QueryBuilder::Vocabulary.query
      do_one('vocabularies', query)
    rescue StandardError => err
      puts err
    end
    CMT.safe_exit
  end

  desc 'terms', 'populate caches with all authority and vocabulary terms'
  def terms
    invoke 'pop:auth:all'
    invoke :vocabs
  end
end

