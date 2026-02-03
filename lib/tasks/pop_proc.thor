# frozen_string_literal: true

require "thor"
require "thor/hollaback"

# tasks populating caches with object/procedure data
class Procedure < Thor
  include CMT::CliHelpers::Pop

  namespace :"pop:proc"

  class_option :debug, desc: "Sets up debug mode", aliases: ["-d"],
    type: :boolean
  class_around :safe_db

  desc "one RECTYPE", "populate CSID cache for ONE procedure record type"
  def one(rectype)
    query_and_populate([CMT::Entity::Procedure.new(rectype)])
  end

  option :rectypes, type: :array
  desc "list --rectypes acquisition loanin",
    "populate CSID cache with for list of procedure record types"
  def list
    rectypes = options[:rectypes].map do |rectype|
      CMT::Entity::Procedure.new(rectype)
    end
    query_and_populate(rectypes)
  end

  desc "all", "populate CSID cache for all procedure record types"
  def all
    query_and_populate(procedures)
  end
end
