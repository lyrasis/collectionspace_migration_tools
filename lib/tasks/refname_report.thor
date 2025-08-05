# frozen_string_literal: true

require "thor"
require "thor/hollaback"

# tasks for writing authority refnames to CSV to be used as lookup tables
class RefnameReport < Thor
  include CMT::CliHelpers
  include Dry::Monads[:result]
  namespace :rr

  class_around :safe_db

  option :rectypes, type: :array, aliases: "-r"
  desc "list --rectypes place-local work-cona",
    "populate caches with refnames and csids for list of authority record types"
  def list
    rectypes = options[:rectypes].map do |rectype|
      CMT::Entity::Authority.from_str(rectype)
    end
    CMT::RefnameReport.write(rectypes)
  end
end
