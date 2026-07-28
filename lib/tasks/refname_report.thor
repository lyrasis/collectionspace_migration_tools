# frozen_string_literal: true

require "thor"

# tasks for writing authority refnames to CSV to be used as lookup tables
class RefnameReport < Thor
  include CMT::CliHelpers
  include Dry::Monads[:result]

  namespace :rr

  option :rectypes, type: :array, aliases: "-r"
  desc "list --rectypes place-local work-cona",
    "write refname report that includes terms in listed authority record types"
  def list
    # rectypes = options[:rectypes].map do |rectype|
    #   CMT::Entity::Authority.from_str(rectype)
    # end
    rectypes = options[:rectypes].map do |rectype|
      CMT::RecordTypes.to_obj(rectype)
    end
    rectypes.select(&:failure?)
      .each { |rt| puts rt.failure }

    CMT::RefnameReport.write(rectypes.select(&:success?).map(&:value!))
  end
end
