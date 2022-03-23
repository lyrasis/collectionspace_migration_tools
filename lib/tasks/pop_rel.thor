# frozen_string_literal: true

require 'thor'
require 'thor/hollaback'

# tasks populating caches with object/procedure data
class Relation < Thor
  include CMT::CliHelpers::Pop
  namespace 'pop:rel'.to_sym

  class_option :debug, desc: 'Sets up debug mode', aliases: ['-d'], type: :boolean
  class_around :safe_db

  desc 'hier', 'populate CSID cache with hierarchical relations'
  def hier
    query_and_populate(*relation_args('hier'))
  end

  desc 'nhr', 'populate CSID cache with non-hierarchical relations'
  def nhr
    query_and_populate(*relation_args('nhr'))
  end

  desc 'all', 'populate CSID cache with all relations'
  def all
    query_and_populate(*relation_args('all'))
  end
end

