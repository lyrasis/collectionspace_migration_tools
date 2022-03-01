# frozen_string_literal: true

require 'thor'
require 'thor/hollaback'

# tasks populating caches with object/procedure data
class Procedure < Thor
  include CMT::CliHelpers
  namespace 'pop:proc'.to_sym

  class_option :debug, desc: 'Sets up debug mode', aliases: ['-d'], type: :boolean
  class_around :safe_db

  desc 'one RECTYPE', 'populate CSID cache for ONE procedure record type'
  def one(rectype)
    query_and_populate(*procedure_args([rectype]))
  end

  option :rectypes, :type => :array
  desc 'list --rectypes place work', 'populate CSID cache with for list of procedure record types'
  def list
    rectypes = options[:rectypes]
    query_and_populate(*procedure_args(rectypes))
  end

  desc 'all', 'populate CSID cache for all procedure record types'
  def all
    query_and_populate(*procedure_args(procedures))
  end
end

