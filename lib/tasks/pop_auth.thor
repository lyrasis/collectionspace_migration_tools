# frozen_string_literal: true

require "thor"
require "thor/hollaback"

# tasks to cache authority data
class Auth < Thor
  include CMT::CliHelpers::Pop
  namespace :"pop:auth"

  class_option :debug, desc: "Sets up debug mode", aliases: ["-d"],
    type: :boolean
  class_around :safe_db

  desc "one RECTYPE",
    "populate caches with refnames and csids for ONE authority record type"
  def one(rectype)
    query_and_populate([CMT::Entity::Authority.from_str(rectype)])
  end

  option :rectypes, type: :array
  desc "list --rectypes place-local work-cona",
    "populate caches with refnames and csids for list of authority record types"
  def list
    rectypes = options[:rectypes].map do |rectype|
      CMT::Entity::Authority.from_str(rectype)
    end
    query_and_populate(rectypes)
  end

  desc "all",
    "populate caches with refnames and csids for all authority record types"
  def all
    query_and_populate(authorities)
  end
end
