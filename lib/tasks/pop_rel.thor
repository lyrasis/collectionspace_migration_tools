# frozen_string_literal: true

require 'thor'
require 'thor/hollaback'

# tasks populating caches with object/procedure data
class Relation < Thor
  include CMT::CliHelpers::Pop
  namespace 'pop:rel'.to_sym

  class_option :debug, desc: 'Sets up debug mode', aliases: ['-d'], type: :boolean
  class_around :safe_db

  desc 'ah', 'populate CSID cache with authorityhierarchy relations'
  def ah
    query_and_populate([CMT::Entity::Relation.new('authorityhierarchy')], :csid)
  end

  desc 'nhr', 'populate CSID cache with non-hierarchical relations'
  def nhr
    query_and_populate([CMT::Entity::Relation.new('nonhierarchicalrelationship')], :csid)
  end

  desc 'oh', 'populate CSID cache with objecthierarchy relations'
  def oh
    query_and_populate([CMT::Entity::Relation.new('objecthierarchy')], :csid)
  end

  desc 'all', 'populate CSID cache with all relations'
  def all
    query_and_populate(relations, :csid)
  end
end

