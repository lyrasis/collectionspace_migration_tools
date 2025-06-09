# frozen_string_literal: true

require "thor"
require "thor/hollaback"

# tasks for writing authority refnames to CSV to be used as lookup tables
class RefnameReport < Thor
  include CMT::CliHelpers
  include Dry::Monads[:result]
  namespace :rr

  class_around :safe_db

  # desc "one RECTYPE",
  #   "populate caches with refnames and csids for ONE authority record type"
  # def one(rectype)
  #   query_and_populate([CMT::Entity::Authority.from_str(rectype)])
  # end

  option :rectypes, type: :array, aliases: "-r"
  desc "list --rectypes place-local work-cona",
    "populate caches with refnames and csids for list of authority record types"
  def list
    rectypes = options[:rectypes].map do |rectype|
      CMT::Entity::Authority.from_str(rectype)
    end
    CMT::RefnameReport.write(rectypes)
  end

  # desc "all",
  #   "populate caches with refnames and csids for all authority record types"
  # def all
  #   query_and_populate(authorities)
  # end
end
